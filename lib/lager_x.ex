defmodule LagerX do
  @default_sink :lager_event

  defdelegate trace_console(filter), to: :lager
  defdelegate trace_file(file, filter, level), to: :lager
  defdelegate stop_trace(trace), to: :lager

  @spec clear_all_traces() :: true
  def clear_all_traces() do
    # workaround for "no local return" warning:
    # - `&:lager.clear_all_traces/0` ultimately calls `&:ets.insert/2`
    # -`&:ets.insert/2` only returns `true`
    # - the warning comes from some funky compiling metaprogramming in goldrush
    # - could have used  `@dialyzer {:nowarn_function, clear_all_traces: 0}`
    # - this approach felt like it had better semantics
    :lager.clear_all_traces() |> throw()
  catch
    i -> i
  end

  defdelegate status(), to: :lager
  defdelegate set_loglevel(handler, level), to: :lager
  defdelegate set_loglevel(handler, indent, level), to: :lager
  defdelegate get_loglevel(handler), to: :lager
  defdelegate posix_error(error), to: :lager
  defdelegate md, to: :lager
  defdelegate md(new_md_list), to: :lager

  levels = [
    debug:      7,
    info:       6,
    notice:     5,
    warning:    4,
    error:      3,
    critical:   2,
    alert:      1,
    emergency:  0,
    none:      -1
  ]

  quoted = for {level, _num} <- levels do
    quote do
      defmacro unquote(level)(message) do
        log(@default_sink, unquote(level), '~ts', [message], __CALLER__)
      end
      defmacro unquote(level)(sink, message) when is_atom(sink) do
        sink_evt = String.to_atom(Atom.to_string(sink) <> "_lager_event")
        log(sink_evt, unquote(level), '~ts', [message], __CALLER__)
      end
      defmacro unquote(level)(format, message) do
        log(@default_sink, unquote(level), format, message, __CALLER__)
      end
      defmacro unquote(level)(sink, format, message) when is_atom(sink) do
        sink_evt = String.to_atom(Atom.to_string(sink) <> "_lager_event")
        log(sink_evt, unquote(level), format, message, __CALLER__)
      end
    end
  end
  Module.eval_quoted __MODULE__, quoted, [], __ENV__

  quoted = for {level, num} <- levels do
    quote do
      defp level_to_num(unquote(level)), do: unquote(num)
    end
  end
  Module.eval_quoted __MODULE__, quoted, [], __ENV__
  defp level_to_num(_), do: nil

  quoted = for {level, num} <- levels do
    quote do
      defp num_to_level(unquote(num)), do:  unquote(level)
    end
  end
  Module.eval_quoted __MODULE__, quoted, [], __ENV__
  defp num_to_level(_), do: nil

  defp log(sink, level, format, args, caller) do
    {name, _arity} = caller.function || {:unknown, 0}
    module = caller.module || :unknown
    format =
      if is_binary(format) do
        String.to_charlist(format)
      else
        format
      end
    if should_log(level) do
      dispatch(sink, level, module, name, caller.line, format, args)
    end
  end

  defp dispatch(sink, level, module, name, line, format, args) do
    quote do
      :lager.dispatch_log(unquote(sink), unquote(level),
        [module: unquote(module),
         function: unquote(name),
         line: unquote(line),
         pid: self(),
         node: node()] ++ :lager.md(),
        unquote(format), unquote(args), unquote(compile_truncation_size()),
        :safe)
    end
  end

  defp should_log(level), do: level_to_num(level) <= level_to_num(compile_log_level())

  @doc """
  This function is used to get compile time log level.
  Examples:
    iex(4)> LagerX.compile_log_level
    :info
  """
  def compile_log_level() do
    level = Application.get_env(:lager_x, :level, :info)
    if is_integer(level) do
      level = num_to_level(level)
      IO.puts "Using integers is deprecated, please use :#{level} instead"
      level
    else
      level
    end
  end

  @doc """
  This function is used to set compile time log level.
  By default the log level is 'info'.
  Examples:
    iex(4)> LagerX.compile_log_level(6)
    true
    iex(4)> LagerX.compile_log_level(:info)
    true
  """
  def compile_log_level(level) when level in -1..7 do
    compile_log_level(num_to_level(level))
  end
  def compile_log_level(level) when is_atom(level) do
    :ok = Application.put_env(:lager_x, :level, level)
    true
  end
  def compile_log_level(level) do
    IO.puts "ERROR: unknown level #{inspect level}"
    false
  end

  def compile_truncation_size() do
    Application.get_env(:lager_x, :truncation_size, 4096)
  end

  @doc """
  This function is used to set compile time truncation size.
  By default the truncation size is 4096.
  Examples:
    iex(4)> LagerX.compile_truncation_size(512)
    true
  """
  def compile_truncation_size(size) do
    :ok = Application.put_env(:lager_x, :truncation_size, size)
    true
  end
end

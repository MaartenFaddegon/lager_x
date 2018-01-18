defmodule :lager_x_passthrough_backend do
  @behaviour :gen_event

  defstruct [
    lager_util_is_loggable: &:lager_util.is_loggable/3,
    lager_util_level_to_num: &:lager_util.level_to_num/1,
    log_level: nil,
    log_level_number: nil,
    passthrough_init_arg: nil,
    passthrough_module: nil,
    passthrough_state: nil,
  ]

  @type call :: :get_loglevel | {:set_loglevel,log_level()} | term()
  @type event :: {:log,message :: :lager_msg.lager_msg()} | term()
  @type init_opts :: [{:passthrough_module,passthrough_module()}|{:passthrough_init_arg,term()},...]
  @type lager_util_is_loggable :: (
    message :: :lager_msg.lager_msg(),
    log_level_number(),
    __MODULE__ -> boolean()
  )
  @type lager_util_level_to_num :: (log_level()->log_level_number())
  @type log_level :: :debug|:info|:notice|:warning|:error|
                     :critical|:alert|:emergency|:none
  @type log_level_number :: non_neg_integer()|{:mask, non_neg_integer()}
  @type on_handle_call :: {:ok,log_level_number(),state()} | {:ok,:ok,state()} | {:ok,reply :: term(),state()} | {:ok,reply :: term(),state(),:hibernate} | {:swap_handler,reply :: term(),args1 :: term(),state(),handler2 :: module(),args2 :: term()} | {:remove_handler,reply :: term()}
  @type on_handle_event :: {:ok,state()} | {:ok,state(),:hibernate} | {:swap_handler,args1 :: term(),state(),handler2 :: module(),args2 :: term()} | :remove_handler
  @type on_handle_info :: {:ok,state()} | {:ok,state(),:hibernate} | {:swap_handler,args1 :: term(),state(),handler2 :: module(),args2 :: term()} | :remove_handler
  @type on_init :: {:ok,state()} | {:ok,state,:hibernate} | {:error,reason :: term()}
  @type on_terminate :: {reason :: term()}
  @type passthrough_init_arg :: term()
  @type passthrough_module :: module()
  @type passthrough_state :: term()
  @type state :: %__MODULE__{
    lager_util_is_loggable: lager_util_is_loggable(),
    lager_util_level_to_num: lager_util_level_to_num(),
    log_level_number: log_level_number,
    passthrough_init_arg: passthrough_init_arg,
    passthrough_module: passthrough_module,
    passthrough_state: passthrough_state,
  }

  #############
  # Callbacks #
  #############

  @spec handle_call(call(),state()) :: on_handle_call()
  def handle_call(call,state)

  def handle_call(:get_loglevel,%__MODULE__{}=state) do
    {:ok,state.log_level_number,state}
  end

  def handle_call({:set_loglevel,log_level},%__MODULE__{}=state) do
    state.lager_util_level_to_num
    |> apply([log_level])
    |> case do
      log_level_number -> struct!(state,log_level_number: log_level_number)
    end
    |> case do
      state2 -> {:ok,:ok,state2}
    end
  end

  def handle_call(call,%__MODULE__{}=state) do
    state.passthrough_module
    |> apply(:handle_call,[call,state.passthrough_state])
    |> case do
      {:ok,reply,passthrough_state} ->
        state
        |> struct!(passthrough_state: passthrough_state)
        |> case do
          state2 -> {:ok,reply,state2}
        end
      {:ok,reply,passthrough_state,:hibernate} ->
        state
        |> struct!(passthrough_state: passthrough_state)
        |> case do
          state2 -> {:ok,reply,state2,:hibernate}
        end
      {:swap_handler,reply,args1,passthrough_state,handler2,args2} ->
        state
        |> struct!(passthrough_state: passthrough_state)
        |> case do
          state2 -> {:swap_handler,reply,args1,state2,handler2,args2}
        end
      {:remove_handler,_reply}=on_remove_handler ->
        on_remove_handler
    end
  end

  @spec handle_event(event(),state()) :: on_handle_event()
  def handle_event(event,state)

  def handle_event({:log,lager_message}=event,%__MODULE__{}=state) do
    state.lager_util_is_loggable
    |> apply([lager_message,state.log_level_number,__MODULE__])
    |> if do
      state.passthrough_module
      |> apply(:handle_event,[event,state.passthrough_state])
      |> case do
        {:ok,passthrough_state} ->
          state
          |> struct!(passthrough_state: passthrough_state)
          |> case do
            state2 -> {:ok,state2}
          end
        {:ok,passthrough_state,:hibernate} ->
          state
          |> struct!(passthrough_state: passthrough_state)
          |> case do
            state2 -> {:ok,state2,:hibernate}
          end
        {:swap_handler,args1,passthrough_state,handler2,args2} ->
          state
          |> struct!(passthrough_state: passthrough_state)
          |> case do
            state2 -> {:swap_handler,args1,state2,handler2,args2}
          end
        :remove_handler=on_remove_handler ->
          on_remove_handler
      end
    else
      {:ok,state}
    end
  end

  def handle_event(_,state) do
    {:ok,state}
  end

  @spec handle_info(info :: term(),state()) :: on_handle_info()
  def handle_info(info,state)

  def handle_info(info,%__MODULE__{}=state) do
    state.passthrough_module
    |> apply(:handle_info,[info,state.passthrough_state])
    |> case do
      {:ok,passthrough_state} ->
        state
        |> struct!(passthrough_state: passthrough_state)
        |> case do
          state2 -> {:ok,state2}
        end
      {:ok,passthrough_state,:hibernate} ->
        state
        |> struct!(passthrough_state: passthrough_state)
        |> case do
          state2 -> {:ok,state2,:hibernate}
        end
      {:swap_handler,args1,passthrough_state,handler2,args2} ->
        state
        |> struct!(passthrough_state: passthrough_state)
        |> case do
          state2 -> {:swap_handler,args1,state2,handler2,args2}
        end
      :remove_handler=on_remove_handler ->
        on_remove_handler
    end
  end

  @spec init(init_opts()) :: on_init()
  def init(opts) do
    _ = Keyword.fetch!(opts,:log_level)
    _ = Keyword.fetch!(opts,:passthrough_init_arg)
    _ = Keyword.fetch!(opts,:passthrough_module)

    __MODULE__
    |> struct!(opts)
    |> case do
      state ->
        struct!(
          state,
          log_level_number: state.lager_util_level_to_num.(IO.inspect(state.log_level)),
        )
    end
    |> case do
      state ->
        state.passthrough_module
        |> apply(:init,[state.passthrough_init_arg])
        |> case do
          {:ok,passthrough_state} ->
            state
            |> struct!(passthrough_state: passthrough_state)
            |> case do
              state2 -> {:ok,state2}
            end
          {:ok,passthrough_state,:hibernate} ->
            state
            |> struct!(passthrough_state: passthrough_state)
            |> case do
              state2 -> {:ok,state2,:hibernate}
            end
          {:error,_reason}=on_error ->
            on_error
      end
    end
  end

  @spec terminate(reason :: term(),state()) :: on_terminate()
  def terminate(reason,state) do
    state.passthrough_module
    |> apply(:terminate,[reason,state.passthrough_state])
  end
end

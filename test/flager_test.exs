defmodule Flager.Test do
  use ExUnit.Case
  @top Path.expand "../..", __ENV__.file

  @tag :potato
  test "debug" do
    {enabled, disabled} = split(compile(:debug))
    assert disabled == []
    assert enabled == [
     :alert, :critical, :debug, :emergency,
     :error, :info, :notice, :warning]
  end

  test "info" do
    {enabled, disabled} = split(compile(:info))
    assert disabled == [:debug]
    assert enabled == [
     :alert, :critical, :emergency,
     :error, :info, :notice, :warning]
  end

  test "notice" do
    {enabled, disabled} = split(compile(:notice))
    assert disabled == [:debug, :info]
    assert enabled == [:alert, :critical, :emergency, :error, :notice, :warning]
  end

  test "warning" do
    {enabled, disabled} = split(compile(:warning))
    assert disabled == [:debug, :info, :notice]
    assert enabled == [:alert, :critical, :emergency, :error, :warning]
  end

  test "error" do
    {enabled, disabled} = split(compile(:error))
    assert disabled == [:debug, :info, :notice, :warning]
    assert enabled == [:alert, :critical, :emergency, :error]
  end

  test "critical" do
    {enabled, disabled} = split(compile(:critical))
    assert disabled == [:debug, :error, :info, :notice, :warning]
    assert enabled == [:alert, :critical, :emergency]
  end

  test "alert" do
    {enabled, disabled} = split(compile(:alert))
    assert disabled == [:critical, :debug, :error, :info, :notice, :warning]
    assert enabled == [:alert, :emergency]
  end

  test "emergency" do
    {enabled, disabled} = split(compile(:emergency))
    assert disabled == [:alert, :critical, :debug, :error, :info, :notice, :warning]
    assert enabled == [:emergency]
  end

  test "none" do
    {enabled, disabled} = split(compile(:none))
    assert disabled == [:alert, :critical, :debug, :emergency,
      :error, :info, :notice, :warning]
    assert enabled == []
  end

  test "compile_log_level(atom)" do
    assert compile_log_level(:debug) == :debug
    assert compile_log_level(:info) == :info
    assert compile_log_level(:notice) == :notice
    assert compile_log_level(:warning) == :warning
    assert compile_log_level(:error) == :error
    assert compile_log_level(:critical) == :critical
    assert compile_log_level(:alert) == :alert
    assert compile_log_level(:emergency) == :emergency
    assert compile_log_level(:none) == :none
  end

  test "compile_log_level(integer)" do
    assert compile_log_level(7) == :debug
    assert compile_log_level(6) == :info
    assert compile_log_level(5) == :notice
    assert compile_log_level(4) == :warning
    assert compile_log_level(3) == :error
    assert compile_log_level(2) == :critical
    assert compile_log_level(1) == :alert
    assert compile_log_level(0) == :emergency
    assert compile_log_level(-1) == :none
  end

  test "get and set metadata" do
    assert [] = Flager.md
    new_md_list = [md1: "foo", md2: "bar"]
    assert :ok = Flager.md(new_md_list)
    assert ^new_md_list = Flager.md
  end

  setup_all do
    on_exit fn -> File.rm("#{@top}/test/#{beam(Flager)}") end
    :ok
  end

  defp compile_log_level(level) do
    true = Flager.compile_log_level(level)
    Flager.compile_log_level
  end

  defp compile(level) do
    :code.purge Flager
    Application.put_env :flager, :level, level
    Kernel.ParallelCompiler.files_to_path ["#{@top}/lib/flager.ex"], "#{@top}/test"
    Code.ensure_compiled(Flager)
    quoted =
      quote do
        require Flager
        [
         debug: Flager.debug("Hi debug"),
         info: Flager.info("Hi info"),
         notice: Flager.notice("Hi notice"),
         warning: Flager.warning("Hi warning"),
         error: Flager.error("Hi error"),
         critical: Flager.critical("Hi critical"),
         alert: Flager.alert("Hi alert"),
         emergency: Flager.emergency("Hi emergency"),
        ]
      end
    {res, _} = Code.eval_quoted quoted
    res
  end

  defp beam(module), do: "#{module}.beam"

  defp split(macros) do
    {e, d} = Enum.reduce macros, {[], []}, fn({level, res}, {e, d}) ->
      if is_nil(res) do
        {e, [level|d]}
      else
        {[level|e], d}
      end
    end
    {Enum.sort(e), Enum.sort(d)}
  end
end

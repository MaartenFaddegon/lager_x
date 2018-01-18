defmodule LagerX.PassthroughBackendTest do
  use ExUnit.Case, async: false

  defmodule Passthrough do
    def handle_call(call,state) do
      state2 = Map.put(state,:last_message,call)

      case call do
        ref when is_reference(ref) ->
          {:ok,call,state2}
        {:hibernate,_} ->
          {:ok,call,state2,:hibernate}
        {:swap_handler,args1,handler2,args2} ->
          {:swap_handler,call,args1,state2,handler2,args2}
        {:remove_handler,_} ->
          {:remove_handler,call}
      end
    end

    def handle_event({:log,test_message}=event,state) do
      state2 = Map.put(state,:last_message,event)

      case test_message do
        ref when is_reference(ref) ->
          {:ok,state2}
        {:hibernate,_event} ->
          {:ok,state2,:hibernate}
        {:swap_handler,ref1,handler2,ref2} ->
          {:swap_handler,ref1,state2,handler2,ref2}
        :remove_handler ->
          :remove_handler
        other ->
          raise "invalid: #{inspect(other)}"
      end
    end

    def handle_info(info,state) do
      state2 = Map.put(state,:last_message,info)

      case info do
        ^info when is_reference(info) ->
          {:ok,state2}
        {:hibernate,_} ->
          {:ok,state2,:hibernate}
        {:swap_handler,args1,handler2,args2} ->
          {:swap_handler,args1,state2,handler2,args2}
        :remove_handler ->
          :remove_handler
      end
    end

    def init(arg) do
      state = %{last_message: arg}
      case arg do
        ^arg when is_reference(arg) ->
          {:ok,state}
        {:hibernate,_} ->
          {:ok,state,:hibernate}
        {:error,_} ->
          {:error,arg}
      end
    end

    def terminate(reason,state) do
      state2 = Map.put(state,:last_message,reason)
      {reason,state2}
    end
  end

  def expected_state(%:lager_x_passthrough_backend{}=state,message) do
    passthrough_state2 = %{last_message: message}
    state2 = struct!(
      state,
       passthrough_state: passthrough_state2
    )

    if state2.log_level_number do
      state2
    else
      struct!(
        state2,
        log_level_number: state.lager_util_level_to_num.(state.log_level)
      )
    end
  end

  def mock_lager_event(event) do
    {:log,event}
  end

  def set_log_level_number() do
    123
  end

  def state() do
    %:lager_x_passthrough_backend{
      lager_util_is_loggable: fn (_,_,_) -> true end,
      lager_util_level_to_num: fn (_) -> set_log_level_number() end,
      log_level_number: 3,
      passthrough_module: Passthrough,
      passthrough_state: %{},
    }
  end

  setup do
    []
    |> Keyword.put(:passthrough_module,Passthrough)
    |> Keyword.put(:set_log_level,:fake_level)
    |> Keyword.put(:set_log_level_number,set_log_level_number())
    |> Keyword.put(:state,state())
    |> case do
     context -> {:ok,context}
    end
  end

  describe "&handle_call/2" do
    test "get_loglevel case",c do
      call = :get_loglevel
      actual = :lager_x_passthrough_backend.handle_call(call,c.state)
      expected = {:ok,c.state.log_level_number,c.state}
      assert actual == expected
    end

    test "set_loglevel case",c do
      call = {:set_loglevel,c.set_log_level}
      actual = :lager_x_passthrough_backend.handle_call(call,c.state)
      expected =
        c.state
        |> struct(log_level_number: c.set_log_level_number)
        |> case do
          state -> {:ok,:ok,state}
        end
      assert actual == expected
    end

    test "stadard case",c do
      call = make_ref()
      actual = :lager_x_passthrough_backend.handle_call(call,c.state)
      expected = {:ok,call,expected_state(c.state,call)}
      assert actual == expected
    end

    test "hibernate case",c do
      call = {:hibernate,make_ref()}
      actual = :lager_x_passthrough_backend.handle_call(call,c.state)
      expected = {:ok,call,expected_state(c.state,call),:hibernate}
      assert actual == expected
    end

    test "swap_handler case",c do
      args1 = [make_ref()]
      handler2 = :fake_handler
      args2 = [make_ref()]
      call = {:swap_handler,args1,handler2,args2}
      actual = :lager_x_passthrough_backend.handle_call(call,c.state)
      expected = {
        :swap_handler,
        call,
        args1,
        expected_state(c.state,call),
        handler2,
        args2
      }
      assert actual == expected
    end

    test "remove_handler case",c do
      call = {:remove_handler,make_ref()}
      actual = :lager_x_passthrough_backend.handle_call(call,c.state)
      expected = {:remove_handler,call}
      assert actual == expected
    end
  end

  describe "&handle_event/2" do
    test "standard case",c do
      event = make_ref() |> mock_lager_event()
      actual = :lager_x_passthrough_backend.handle_event(event,c.state)
      expected = {:ok,expected_state(c.state,event)}
      assert actual == expected
    end

    test "hibernate case",c do
      event = {:hibernate,make_ref()} |> mock_lager_event()
      actual = :lager_x_passthrough_backend.handle_event(event,c.state)
      expected = {:ok,expected_state(c.state,event),:hibernate}
      assert actual == expected
    end

    test "swap_handler case",c do
      args1 = [make_ref()]
      handler2 = :fake_handler
      args2 = [make_ref()]
      event = {:swap_handler,args1,handler2,args2}|> mock_lager_event()
      actual = :lager_x_passthrough_backend.handle_event(event,c.state)
      expected = {
        :swap_handler,
        args1,
        expected_state(c.state,event),
        handler2,
        args2
      }
      assert actual == expected
    end

    test "remove_handler case",c do
      event = :remove_handler |> mock_lager_event()
      actual = :lager_x_passthrough_backend.handle_event(event,c.state)
      expected = :remove_handler
      assert actual == expected
    end

    test "non lager event case",c do
      event = :non_log_event
      actual = :lager_x_passthrough_backend.handle_event(event,c.state)
      expected = {:ok,c.state}
      assert actual == expected
    end
  end

  describe "&handle_info/2" do
    test "standard path",c do
      info = make_ref()
      actual = :lager_x_passthrough_backend.handle_info(info,c.state)
      expected = {:ok,expected_state(c.state,info)}
      assert actual == expected
    end

    test "hibernate path",c do
      info = {:hibernate,make_ref()}
      actual = :lager_x_passthrough_backend.handle_info(info,c.state)
      expected = {:ok,expected_state(c.state,info),:hibernate}
      assert actual == expected
    end

    test "swap_handler path",c do
      args1 = [make_ref()]
      handler2 = :fake_handler
      args2 = [make_ref()]
      info = {:swap_handler,args1,handler2,args2}
      actual = :lager_x_passthrough_backend.handle_info(info,c.state)
      expected = {
        :swap_handler,
        args1,
        expected_state(c.state,info),
        handler2,
        args2
      }
      assert actual == expected
    end

    test "remove_handler path",c do
      info = :remove_handler
      actual = :lager_x_passthrough_backend.handle_info(info,c.state)
      expected = :remove_handler
      assert actual == expected
    end
  end

  describe "&init/1" do
    test "missing log_level case",c do
      opts = [
        passthrough_init_arg: [],
        passthrough_module: c.passthrough_module,
      ]
      func = fn -> :lager_x_passthrough_backend.init(opts) end
      assert_raise KeyError,~r/key :log_level not found in/,func
    end

    test "missing passthrough_module case",c do
      opts = [
        log_level: c.set_log_level,
        passthrough_init_arg: [],
      ]
      func = fn -> :lager_x_passthrough_backend.init(opts) end
      assert_raise KeyError,~r/key :passthrough_module not found in/,func
    end

    test "missing passthrough_init_arg case",c do
      opts = [
        log_level: c.set_log_level,
        passthrough_module: c.passthrough_module,
      ]
      func = fn -> :lager_x_passthrough_backend.init(opts) end
      # assert_raise KeyError, func
      assert_raise KeyError,~r/key :passthrough_init_arg not found in/,func
    end

    test "standard path",c do
      arg = make_ref()
      opts = [
        lager_util_is_loggable: fn (_,_,_) -> true end,
        lager_util_level_to_num: fn (_) -> set_log_level_number() end,
        log_level: c.set_log_level,
        passthrough_init_arg: arg,
        passthrough_module: c.passthrough_module,
      ]
      actual = :lager_x_passthrough_backend.init(opts)
      expected =
        opts
        |> case do
          opts2 -> struct!(:lager_x_passthrough_backend,opts2)
        end
        |> case do
          state -> {:ok,expected_state(state,arg)}
        end
      assert actual == expected
    end

    test "hibernate path",c do
      arg = {:hibernate,make_ref()}
      opts = [
        lager_util_is_loggable: fn (_,_,_) -> true end,
        lager_util_level_to_num: fn (_) -> set_log_level_number() end,
        log_level: c.set_log_level,
        passthrough_init_arg: arg,
        passthrough_module: c.passthrough_module,
      ]
      actual = :lager_x_passthrough_backend.init(opts)
      expected =
        opts
        |> case do
          opts2 -> struct!(:lager_x_passthrough_backend,opts2)
        end
        |> case do
          state -> {:ok,expected_state(state,arg),:hibernate}
        end
      assert actual == expected
    end

    test "error path",c do
      arg = {:error,make_ref()}
      opts = [
        lager_util_is_loggable: fn (_,_,_) -> true end,
        lager_util_level_to_num: fn (_) -> set_log_level_number() end,
        log_level: c.set_log_level,
        passthrough_init_arg: arg,
        passthrough_module: c.passthrough_module,
      ]
      actual = :lager_x_passthrough_backend.init(opts)
      expected = {:error,arg}
      assert actual == expected
    end
  end

  test "&terminate/2",c do
    reason = make_ref()
    actual = :lager_x_passthrough_backend.terminate(reason,c.state)
    expected = {reason,%{last_message: reason}}
    assert actual == expected
  end
end

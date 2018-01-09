defmodule Flager.Backend do
  @callback handle_call(call :: any(),state :: any()) :: any()

  @callback handle_event(event :: any(),state :: any()) :: any()

  @callback handle_info(info :: any(),state :: any()) :: any()

  @callback init(opts :: any()) :: any()

  @callback terminate(reason :: any(), state :: any()) :: any
end

ExLager
=======

This package implements a simple wrapper over https://github.com/basho/lager.

It embeds logging calls to ExLager into a module if currently configured logging
level is less or equal than severity of a call. Therefore it doesn't have
any negative impact on performance of a production system when you configure
error level even if you have tons of debug messages.

Information about location of a call (module, function, line, pid) is properly
passed to lager for your convenience so you can easily find the source of a message.
In this aspect using ExLager is equal to using parse transform shipped with
basho lager.

Since ExLager depends on macro implemented in Lager module you have to require it.
Then you call one of logging methods on Lager module. There are seven logging
methods in order of severity:

 - debug
 - info
 - notice
 - warning
 - error
 - critical
 - alert
 - emergency

Examples:
---------

```elixir
defmodule Test do
  require Lager
  def debug do
    Lager.debug "Hi debug"
  end
  def info do
    Lager.info "Hi error"
  end
  def notice do
    Lager.notice "Hi notice"
  end
  def warning do
    Lager.warning "Hi warning"
  end
  def error do
    Lager.error "Hi error"
  end
  def critical do
    Lager.critical "Hi critical"
  end
  def alert do
    Lager.alert "Hi alert"
  end
  def emergency do
    Lager.emergency "Hi emergency"
  end
  def test do
    debug
    info
    notice
    warning
    error
    critical
    alert
    emergency
  end
end

Application.start :exlager
Test.test
```

Configuration
-------------
It is possible to configure truncation size and compile time log level.
Being a simple wrapper ExLager doesn't attempt to configure underlying Lager.
You would need to configure it yourself [see](https://github.com/basho/lager) to ensure that:

  * lager_truncation_size >= compile_truncation_size
  * lager severity level >= compile_log_level
  * appropriate handlers are configured

Configuration of ExLager can be done by calling helper functions of Lager from your build system as follows:

```
iex(1)> Lager.compile_log_level(:info)
true
iex(2)> Lager.compile_truncation_size(512)
true
```

If you cannot call those function you can set compiler options:

```
iex(3)> Code.compiler_options exlager_level: :debug
ok
iex(4)> Code.compiler_options exlager_truncation_size: 512
ok
```

If you are mix user you could specify level and truncation_size in *config/config.#{Mix.env}.exs* as follows:

```
    use Mix.Config

    config :exlager,
      level: :debug,
      truncation_size: 8096
```

Multiple Sink Support
---------------------
As of Lager 3.x, you can configure multiple sinks to provide different behavior
for different streams of logs.  To use a different sink, prepend the name to the
logging calls above.  For example, to use the `magic_lager_event` sink, you can
do the following:

```
Lager.info :magic, "magic event"
```

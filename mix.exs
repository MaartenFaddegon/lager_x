defmodule LagerX.Mixfile do
  use Mix.Project

  #######
  # API #
  #######

  def application() do
    [
      applications: [
        :compiler,
        :syntax_tools,
        :lager
      ],
    ]
  end

  def project() do
    [
      app: :lager_x,
      description: description(),
      deps: deps(),
      elixir: "~> 1.5",
      package: package(),
      version: "0.14.2",
    ]
  end

  ###########
  # Private #
  ###########

  defp deps() do
    [
      # static analysis
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      # doc generator
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      # event logging
      {:lager, "~> 3.2"},
    ]
  end

  defp description() do
    "An Elixir wrapper for Lager, an Erlang logging library Edit Add topics"
  end

  defp licenses() do
    ["Apache 2.0"]
  end

  defp links() do
    %{"GitHub" => "https://github.com/amorphid/lager_x"}
  end

  defp maintainers() do
    ["Michael Pope"]
  end

  defp package() do
    [
      licenses: licenses(),
      links: links(),
      maintainers: maintainers(),
    ]
  end
end

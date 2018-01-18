defmodule LagerX.Mixfile do
  use Mix.Project

  def project do
    [
      app: :lager_x,
      version: "0.14.1",
      elixir: "> 0.14.0",
      deps: deps()
    ]
  end

  def application do
    [
      applications: [
        :compiler,
        :syntax_tools,
        :lager
      ],
    ]
  end

  defp deps do
    [
      # static analysis
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      # doc generator
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      # event logging
      {:lager, "~> 3.2.4"},
    ]
  end
end

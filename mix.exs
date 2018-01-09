defmodule Flager.Mixfile do
  use Mix.Project

  def project do
    [
      app: :flager,
      version: "0.15.0",
      elixir: "~> 1.5",
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
      # doc generator
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      # logging library
      {:lager, git: "https://github.com/basho/lager.git", tag: "3.2.4"},
    ]
  end
end

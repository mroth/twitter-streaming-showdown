defmodule Exfeeder.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exfeeder,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps,
      escript: [main_module: Exfeeder]
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger],
     mod: {Exfeeder, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:oauth,      github: "tim/erlang-oauth"},
      {:extwitter,  "~> 0.2.1"}
    ]
  end
end

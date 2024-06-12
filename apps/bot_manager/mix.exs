defmodule BotManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :bot_manager,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :plug_cowboy],
      mod: {BotManager.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      # server
      {:plug_cowboy, "~> 2.2"},
      {:jason, "~> 1.2"},
      {:websockex, "~> 0.4.3"},
      {:exbase58, "~> 1.0.2"},
      {:protobuf, "~> 0.12.0"},
      {:finch, "~> 0.13"},
    ]
  end
end

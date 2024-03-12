defmodule MirraBackend.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      apps: [:arena, :champions, :game_client, :gateway, :game_backend, :bot_manager],
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      releases: releases(),
      default_release: :all
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    []
  end

  defp aliases() do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end

  defp releases() do
    [
      all: [
        applications: [
          arena: :permanent,
          champions: :permanent,
          game_backend: :permanent,
          game_client: :permanent,
          gateway: :permanent
        ]
      ]
    ]
  end
end

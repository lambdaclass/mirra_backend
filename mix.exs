defmodule MirraBackend.MixProject do
  use Mix.Project

  def project do
    [
      name: "mirra_backend",
      apps_path: "apps",
      apps: [
        :arena,
        :champions,
        :game_client,
        :gateway,
        :game_backend,
        :arena_load_test,
        :configurator,
        :bot_manager
      ],
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
    [{:ex_doc, "~> 0.21", only: :dev, runtime: false}]
  end

  defp aliases() do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.reset --quiet", "ecto.migrate --quiet", "run priv/repo/seeds.exs", "test"]
    ]
  end

  defp releases() do
    [
      arena: [applications: [arena: :permanent]],
      arena_load_test: [applications: [arena_load_test: :permanent]],
      game_client: [applications: [game_client: :permanent]],
      game_backend: [
        applications: [
          champions: :permanent,
          game_backend: :permanent,
          gateway: :permanent
        ]
      ]
    ]
  end
end

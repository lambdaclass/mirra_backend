defmodule GameBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :game_backend,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      # mod: {GameBackend.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:phoenix_pubsub, "~> 2.0"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:rustler, "~> 0.30.0"},
      {:protobuf, "~> 0.12.0"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:exbase58, "~> 1.0.2"}
    ]
  end
end

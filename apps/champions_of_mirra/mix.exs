defmodule ChampionsOfMirra.MixProject do
  use Mix.Project

  def project do
    [
      app: :champions_of_mirra,
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
      extra_applications: [:logger],
      mod: {ChampionsOfMirra.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:units, in_umbrella: true},
      {:users, in_umbrella: true},
      {:math, "~> 0.7.0"},
      {:ecto, "~> 3.11"},
      {:ecto_sql, "~> 3.6"}
    ]
  end
end

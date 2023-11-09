defmodule LambdaGameEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :lambda_backend_game_engine,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.29.1"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end

defmodule LambdaGameBackend.Repo do
  use Ecto.Repo,
    otp_app: :lambda_game_backend,
    adapter: Ecto.Adapters.Postgres
end

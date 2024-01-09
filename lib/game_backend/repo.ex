defmodule GameBackend.Repo do
  use Ecto.Repo,
    otp_app: :game_backend,
    adapter: Ecto.Adapters.Postgres
end

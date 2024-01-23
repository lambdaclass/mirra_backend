defmodule GameClient.Repo do
  use Ecto.Repo,
    otp_app: :game_client,
    adapter: Ecto.Adapters.Postgres
end

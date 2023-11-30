defmodule DarkWorldsServer.Repo do
  use Ecto.Repo,
    otp_app: :dark_worlds_server,
    adapter: Ecto.Adapters.Postgres
end

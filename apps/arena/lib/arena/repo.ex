defmodule Arena.Repo do
  use Ecto.Repo,
    otp_app: :arena,
    adapter: Ecto.Adapters.Postgres
end

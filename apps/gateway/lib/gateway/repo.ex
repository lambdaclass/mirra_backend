defmodule Gateway.Repo do
  use Ecto.Repo,
    otp_app: :gateway,
    adapter: Ecto.Adapters.Postgres
end

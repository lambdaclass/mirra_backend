defmodule Configurator.Repo do
  use Ecto.Repo,
    otp_app: :configurator,
    adapter: Ecto.Adapters.Postgres
end

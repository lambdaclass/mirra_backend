defmodule MirraBackend.Repo do
  use Ecto.Repo,
    otp_app: :mirra_backend,
    adapter: Ecto.Adapters.Postgres
end

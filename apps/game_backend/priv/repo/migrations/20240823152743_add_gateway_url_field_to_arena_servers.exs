defmodule GameBackend.Repo.Migrations.AddGatewayUrlFieldToArenaServers do
  use Ecto.Migration

  def change do
    alter table(:arena_servers) do
      add :gateway_url, :string
    end
  end
end

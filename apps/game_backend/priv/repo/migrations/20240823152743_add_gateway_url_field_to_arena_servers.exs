defmodule GameBackend.Repo.Migrations.AddGatewayUrlFieldToArenaServers do
  use Ecto.Migration

  def change do
    alter table(:arena_servers) do
      add :gateway_url, :string
    end

    execute("""
    UPDATE arena_servers arena_server
    SET gateway_url = 'https://central-europe-staging.championsofmirra.com';
    """, "")
  end
end

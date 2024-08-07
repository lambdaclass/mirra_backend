defmodule Configurator.Repo.Migrations.CreateArenaServers do
  use Ecto.Migration

  def change do
    create table(:arena_servers) do
      add :name, :string
      add :ip, :string
      add :url, :string
      add :status, :string
      add :environment, :string

      timestamps(type: :utc_datetime)
    end
  end
end

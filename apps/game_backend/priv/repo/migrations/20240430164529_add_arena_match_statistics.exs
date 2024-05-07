defmodule GameBackend.Repo.Migrations.AddArenaMatchStatistics do
  use Ecto.Migration

  def change do
    create table(:arena_match_statistics) do
      add :match_id, :uuid, null: false
      add :data, :binary, null: false
      timestamps()
    end
  end
end

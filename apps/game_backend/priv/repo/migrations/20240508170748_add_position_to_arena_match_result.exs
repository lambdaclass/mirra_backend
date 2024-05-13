defmodule GameBackend.Repo.Migrations.AddPositionToArenaMatchResult do
  use Ecto.Migration

  def change do
    alter table(:arena_match_results) do
      add :position, :integer, null: false
    end
  end
end

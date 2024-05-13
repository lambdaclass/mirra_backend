defmodule GameBackend.Repo.Migrations.AddMoreMatchResultsData do
  use Ecto.Migration

  def change do
    alter table(:arena_match_results) do
      add :damage_done, :integer, default: 0, null: false
      add :damage_taken, :integer, default: 0, null: false
      add :health_healed, :integer, default: 0, null: false
      add :killed_by, :string
      add :killed_by_bot, :boolean, default: false, null: false
    end
  end
end

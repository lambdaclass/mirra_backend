defmodule GameBackend.Repo.Migrations.AddMoreMatchResultsData do
  use Ecto.Migration

  def change do
    alter table(:arena_match_results) do
      add :damage_done, :integer
      add :damage_taken, :integer
      add :health_healed, :integer
      add :killed_by, :string
      add :killed_by_bot, :boolean
      add :duration_ms, :integer
    end

    ## This is to allow us to later set `null: false` on all the new columns
    ## without having to set a default value when adding the column
    ## Having a default value in the DB could lead to us having a hidden bug or wrong values if
    ## it where to be used by accident
    query = """
            UPDATE arena_match_results
            SET duration_ms = 600000, damage_done = 0, damage_taken = 0, health_healed = 0, killed_by_bot = false
            WHERE duration_ms IS NULL
            """
    execute(query, "")

    alter table(:arena_match_results) do
      modify :duration_ms, :integer, from: :integer, null: false
      modify :damage_done, :integer, from: :integer, null: false
      modify :damage_taken, :integer, from: :integer, null: false
      modify :health_healed, :integer, from: :integer, null: false
      modify :killed_by_bot, :boolean, from: :boolean, null: false
    end
  end
end

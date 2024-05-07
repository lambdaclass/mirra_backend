defmodule GameBackend.Repo.Migrations.AddArenaMatchResults do
  use Ecto.Migration

  def change do
    create table(:arena_match_results) do
      add :user_id, references(:google_users, on_delete: :delete_all), null: false
      add :result, :string, null: false
      add :kills, :integer, null: false
      add :deaths, :integer, null: false
      add :character, :string, null: false
      add :match_id, :uuid, null: false
      timestamps()
    end
  end
end

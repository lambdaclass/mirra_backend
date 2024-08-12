defmodule GameBackend.Repo.Migrations.AddGameModeRelationToVersion do
  use Ecto.Migration

  def change do
    alter table(:versions) do
      add :game_mode_id, references(:game_modes, on_delete: :nothing)
    end
  end
end

defmodule GameBackend.Repo.Migrations.AddGameModeConfigurations do
  use Ecto.Migration

  def change do
    alter table(:game_configurations) do
      add :mode, :string
      add :respawn_time_ms, :integer
      add :match_duration_ms, :integer
    end

    execute("UPDATE game_configurations SET mode = 'battle_royale'", "")
  end
end

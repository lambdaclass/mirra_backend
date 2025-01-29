defmodule GameBackend.Repo.Migrations.AddNewFieldsToGameModeSchema do
  use Ecto.Migration

  def change do
    rename table(:game_mode_configurations), :name, to: :type

    alter table(:game_mode_configurations) do
      add :name, :string
      add :respawn_time, :integer
      add :team_enabled, :boolean
      add :team_size, :integer
      add :amount_of_players, :integer
    end

    alter table(:map_mode_params) do
      remove :amount_of_players
    end
  end
end

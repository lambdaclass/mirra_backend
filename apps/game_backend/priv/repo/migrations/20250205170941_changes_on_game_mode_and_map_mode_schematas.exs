defmodule GameBackend.Repo.Migrations.ChangesOnGameModeAndMapModeSchematas do
  use Ecto.Migration

  def change do
    alter table(:map_mode_params) do
      remove :solo_initial_positions
      remove :team_initial_positions

      add :initial_positions, :map
      add :amount_of_players, :integer
    end

    alter table(:game_mode_configurations) do
      remove :amount_of_players
      remove :team_enabled
    end
  end
end

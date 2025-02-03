defmodule GameBackend.Repo.Migrations.RestoreAmountOfPlayersInMapModeParams do
  use Ecto.Migration

  def change do
    alter table(:game_mode_configurations) do
      remove :amount_of_players
    end

    alter table(:map_mode_params) do
      add :amount_of_players, :integer
    end
  end
end

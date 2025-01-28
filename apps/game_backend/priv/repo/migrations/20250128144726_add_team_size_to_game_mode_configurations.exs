defmodule GameBackend.Repo.Migrations.AddTeamSizeToGameModeConfigurations do
  use Ecto.Migration

  def change do
    alter table(:game_mode_configurations) do
      add :team_size, :integer
    end
  end
end

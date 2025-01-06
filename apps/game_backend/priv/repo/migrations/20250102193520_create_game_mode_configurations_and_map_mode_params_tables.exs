defmodule GameBackend.Repo.Migrations.CreateGameModeConfigurationsAndMapModeParamsTables do
  use Ecto.Migration

  def change do
    create table(:game_mode_configurations) do
      add :name, :string
      add :zone_enabled, :boolean, default: false
      add :bots_enabled, :boolean, default: false
      add :match_duration_ms, :integer
      add :respawn_time_ms, :integer
      add :version_id, references(:versions)
      add :deleted_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end

    create table(:map_mode_params) do
      add :map_id, references(:map_configurations)
      add :game_mode_id, references(:game_mode_configurations)
      add :amount_of_players, :integer
      add :solo_initial_positions, :map
      add :team_initial_positions, :map
      add :deleted_at, :naive_datetime

      timestamps(type: :utc_datetime)
    end
  end
end

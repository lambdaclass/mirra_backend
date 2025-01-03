defmodule GameBackend.Repo.Migrations.CreateGameModeConfigurationsAndMapModeParamsTables do
  use Ecto.Migration

  def change do
    create table(:game_mode_configurations) do
      add :name, :string
      add :zone_enabled, :boolean
      add :bots_enabled, :boolean
      add :match_duration_ms, :integer
      add :respawn_time_ms, :integer
      add :version_id, references(:versions)

      timestamps(type: :utc_datetime)
    end

    create table(:map_mode_params) do
      add :map_id, references(:map_configurations)
      add :game_mode_id, references(:game_mode_configurations)
      add :amount_of_players, :integer
      add :initial_positions, :map

      timestamps(type: :utc_datetime)
    end

    create table(:initial_positions) do
      add :team_mode, :string
      add :positions, :map
      add :map_mode_params_id, references(:map_mode_params)

      timestamps(type: :utc_datetime)
    end
  end
end

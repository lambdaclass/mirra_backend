defmodule Configurator.Repo.Migrations.CreateGameConfigurations do
  use Ecto.Migration

  def change do
    create table(:game_configurations) do
      add :end_game_interval_ms, :integer, null: false
      add :item_spawn_interval_ms, :integer, null: false
      add :natural_healing_interval_ms, :integer, null: false
      add :shutdown_game_wait_ms, :integer, null: false
      add :start_game_time_ms, :integer, null: false
      add :tick_rate_ms, :integer, null: false
      add :zone_damage_interval_ms, :integer, null: false
      add :zone_damage, :integer, null: false
      add :zone_shrink_interval, :integer, null: false
      add :zone_shrink_radius_by, :integer, null: false
      add :zone_shrink_start_ms, :integer, null: false
      add :zone_start_interval_ms, :integer, null: false
      add :zone_stop_interval_ms, :integer

      timestamps(type: :utc_datetime)
    end
  end
end

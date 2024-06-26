defmodule GameBackend.Repo.Migrations.AddGameConfiguration do
  use Ecto.Migration

  def change do
    create table(:game_configurations) do
      add :tick_rate_ms, :integer
      add :bounty_pick_time_ms, :integer
      add :start_game_time_ms, :integer
      add :end_game_interval_ms, :integer
      add :shutdown_game_wait_ms, :integer
      add :natural_healing_interval_ms, :integer
      add :zone_shrink_start_ms, :integer
      add :zone_shrink_radius_by, :integer
      add :zone_shrink_interval, :integer
      add :zone_stop_interval_ms, :integer
      add :zone_start_interval_ms, :integer
      add :zone_damage_interval_ms, :integer
      add :zone_damage, :integer
      add :item_spawn_interval_ms, :integer
      add :bots_enabled, :boolean, default: false
      add :zone_enabled, :boolean, default: false

      timestamps(type: :utc_datetime)
    end
  end
end

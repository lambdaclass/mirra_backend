defmodule GameBackend.Repo.Migrations.AddPowerUpConfigToGameConfiguration do
  use Ecto.Migration

  def change do
    alter table(:game_configurations) do
      add :distance_to_power_up, :integer
      add :power_up_damage_modifier, :float
      add :power_up_health_modifier, :float
      add :power_up_radius, :float
      add :power_up_activation_delay_ms, :integer
      add :power_ups_per_kill, :map
    end

  end
end

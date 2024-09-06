defmodule GameBackend.Repo.Migrations.AddZoneRandomPositionRadiusToGameConfiguration do
  use Ecto.Migration

  def change do
    alter table(:game_configurations) do
      add :zone_random_position_radius, :integer
    end
  end
end

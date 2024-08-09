defmodule GameBackend.Repo.Migrations.AddZoneFieldsToGameConfiguration do
  use Ecto.Migration

  def change do
    alter table(:game_configurations) do
      add :zone_start_radius, :float
      add :zone_random_position_radius, :integer
    end
  end
end

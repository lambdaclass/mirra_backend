defmodule GameBackend.Repo.Migrations.AddPoolsPositionToMechanics do
  use Ecto.Migration

  def change do
    alter table(:mechanics) do
      add :pools_angle, {:array, :float}
      add :distance_to_pools, :float
    end
  end
end

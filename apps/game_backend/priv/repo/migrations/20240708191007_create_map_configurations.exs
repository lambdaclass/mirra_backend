defmodule Configurator.Repo.Migrations.CreateMapConfigurations do
  use Ecto.Migration

  def change do
    create table(:map_configurations) do
      add :radius, :decimal
      add :initial_positions, :map
      add :obstacles, :map
      add :bushes, :map

      timestamps(type: :utc_datetime)
    end
  end
end

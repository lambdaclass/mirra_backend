defmodule Configurator.Repo.Migrations.CreateConsumableItems do
  use Ecto.Migration

  def change do
    create table(:consumable_items) do
      add :name, :string
      add :radius, :float
      add :effects, {:array, :string}

      timestamps(type: :utc_datetime)
    end
  end
end

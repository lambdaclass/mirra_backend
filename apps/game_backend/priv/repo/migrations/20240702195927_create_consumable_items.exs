defmodule Configurator.Repo.Migrations.CreateConsumableItems do
  use Ecto.Migration

  def change do
    create table(:consumable_items) do
      add :name, :string
      add :radius, :float
      add :effects, {:array, :string}
      add :mechanics, {:map, :map}
      add :active, :boolean, default: false

      timestamps(type: :utc_datetime)
    end
  end
end

defmodule Configurator.Repo.Migrations.AddExtraFieldsToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :max_inventory_size, :integer
      add :natural_healing_interval, :integer
      add :natural_healing_damage_interval, :integer
      add :stamina_interval, :integer
      add :skills, :map
    end
  end
end

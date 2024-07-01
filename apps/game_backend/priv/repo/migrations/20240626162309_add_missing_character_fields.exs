defmodule GameBackend.Repo.Migrations.AddMissingCharacterFields do
  use Ecto.Migration

  def change do
    alter table :characters do
      add :base_speed, :float
      add :base_size, :float
      add :base_stamina, :integer
      add :stamina_interval, :integer
      add :max_inventory_size, :integer
      add :natural_healing_interval, :integer
      add :natural_healing_damage_interval, :integer
      add :skills, :map
    end
  end
end

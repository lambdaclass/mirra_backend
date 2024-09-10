defmodule GameBackend.Repo.Migrations.AddMechanicsToConsumableItems do
  use Ecto.Migration

  def change do
    alter table(:mechanics) do
      add :consumable_item_id, references(:consumable_items)
      add :activation_delay_ms, :integer
      add :preparation_delay_ms, :integer
      add :activate_on_proximity, :boolean
    end
  end
end

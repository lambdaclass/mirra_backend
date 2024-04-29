defmodule GameBackend.Repo.Migrations.AddItemTemplateFields do
  use Ecto.Migration

  def change do
    alter(table(:item_templates)) do
      add(:rarity, :integer)
      add(:config_id, :string)
      add(:upgrades_from_quantity, :integer)
      add(:upgrade_costs, {:array, :map})
      add(:modifiers, {:array, :map})
      remove(:base_modifiers)
    end

    create(unique_index(:item_templates, [:config_id]))
    drop(unique_index(:item_templates, [:game_id, :name]))

    alter(table(:item_templates)) do
      add(:upgrades_from_config_id, references(:item_templates, on_delete: :nothing, column: :config_id, type: :string))
    end

    alter(table(:items)) do
      remove(:level)
    end
  end
end

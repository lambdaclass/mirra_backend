defmodule GameBackend.Repo.Migrations.AddAbstractUpgradeCostToKalineTreeLevels do
  use Ecto.Migration

  def change do
    alter table(:kaline_tree_levels) do
      add(:upgrade_cost, :map)
      remove(:fertilizer_level_up_cost)
      remove(:gold_level_up_cost)
    end
  end
end

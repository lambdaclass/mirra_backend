defmodule GameBackend.Repo.Migrations.AddAbstractUpgradeCostToKalineTreeLevels do
  use Ecto.Migration

  def change do
    alter table(:kaline_tree_levels) do
      add(:experience_reward_rate, :float)
      add(:level_up_cost, :map)
      remove(:fertilizer_level_up_cost)
      remove(:gold_level_up_cost)
    end
  end
end

defmodule GameBackend.Repo.Migrations.MoveAfkRewardsIncrementToKalineTreeLevel do
  use Ecto.Migration

  def change do
    alter(table(:kaline_tree_levels)) do
      add(:afk_rewards_increment_id, references(:currency_rewards, on_delete: :delete_all))
    end

    alter(table(:levels)) do
      remove(:afk_rewards_increment_id)
    end
  end
end

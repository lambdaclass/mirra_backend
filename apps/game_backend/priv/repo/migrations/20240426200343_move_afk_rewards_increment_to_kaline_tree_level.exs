defmodule GameBackend.Repo.Migrations.MoveAfkRewardsIncrementToKalineTreeLevel do
  use Ecto.Migration

  def change do
    alter(table(:kaline_tree_levels)) do
      add(:afk_rewards_increment_id, references(:currency_rewards, on_delete: :delete_all))
    end

    alter(table(:levels)) do
      remove(:afk_rewards_increment_id)
    end

    alter(table(:currency_rewards)) do
      remove(:afk_reward)
    end

    create(table(:afk_reward_increments)) do
      add(:kaline_tree_level_id, references(:kaline_tree_levels, on_delete: :delete_all))
      add(:currency_id, references(:currencies, on_delete: :delete_all))
      add(:amount, :integer)
      timestamps()
    end
  end
end

defmodule GameBackend.Repo.Migrations.MoveAfkRewardsIncrementToKalineTreeLevel do
  use Ecto.Migration

  def change do
    alter(table(:levels)) do
      remove(:afk_rewards_increment_id)
    end

    alter(table(:currency_rewards)) do
      remove(:afk_reward)
    end
  end
end

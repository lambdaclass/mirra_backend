defmodule GameBackend.Repo.Migrations.AddDailyRewardsFieldsToUser do
  use Ecto.Migration

  def change do
    alter(table(:users)) do
      add(:last_daily_reward_claim_at, :utc_datetime)
      add(:last_daily_reward_claim, :string)
    end
  end
end

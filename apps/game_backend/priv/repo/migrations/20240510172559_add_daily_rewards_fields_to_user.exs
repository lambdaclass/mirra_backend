defmodule GameBackend.Repo.Migrations.AddDailyRewardsFieldsToUser do
  use Ecto.Migration

  def change do
    alter(table(:users)) do
      add(:last_daily_reward_claim, :utc_datetime)
      add(:last_daily_reward_claim_type, :string)
    end
  end
end

defmodule GameBackend.Repo.Migrations.AddExperienceAndAfkRewards do
  use Ecto.Migration

  def change do
    create(table(:afk_reward_rates)) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:currency_id, references(:currencies, on_delete: :delete_all))
      add(:rate, :integer, null: false)
      timestamps()
    end

    alter(table(:levels)) do
      add(:experience_reward, :integer)
      add(:afk_rewards_incrementer_id, references(:currency_rewards, on_delete: :delete_all))
    end

    alter(table(:users)) do
      add(:last_afk_reward_claim, :utc_datetime, default: fragment("now()"))
    end
  end
end

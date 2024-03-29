defmodule GameBackend.Repo.Migrations.AddAfkRewards do
  use Ecto.Migration

  def change do
    create(table(:afk_reward_rates)) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:currency_id, references(:currencies, on_delete: :delete_all))
      add(:rate, :float, null: false)
      timestamps()
    end

    alter(table(:levels)) do
      add(:afk_rewards_increment_id, references(:currency_rewards, on_delete: :delete_all))
    end

    alter(table(:users)) do
      add(:last_afk_reward_claim, :utc_datetime, default: fragment("now()"))
    end
  end
end

defmodule GameBackend.Repo.Migrations.RenameRateToDailyRate do
  use Ecto.Migration

  def change do
    alter(table(:afk_reward_rates)) do
      remove(:rate)
      add(:daily_rate, :float, null: false)
    end
  end
end

defmodule GameBackend.Repo.Migrations.AddMana do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :base_mana, :integer
      add :initial_mana, :integer
      add :mana_recovery_strategy, :string
      add :mana_recovery_time_interval_ms, :integer
      add :mana_recovery_time_amount, :integer
      add :mana_recovery_damage_multiplier, :decimal
    end

    execute(
      """
      UPDATE characters
      SET base_mana = 100,
        initial_mana = 50,
        mana_recovery_strategy = 'time',
        mana_recovery_time_interval_ms = 1000,
        mana_recovery_time_amount = 10
      WHERE game_id = 1 AND mana_recovery_strategy IS NULL
      """, "")

    alter table(:skills) do
      add :mana_cost, :integer
    end

    execute(
      """
      UPDATE skills
      SET mana_cost = 100
      WHERE game_id = 1 AND type = 'ultimate' AND mana_cost IS NULL
      """, "")
  end
end

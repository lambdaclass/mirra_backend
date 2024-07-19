defmodule GameBackend.Repo.Migrations.AddMana do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :base_mana, :integer
      add :initial_mana, :integer
      add :mana_recovery_strategy, :string
      add :mana_recovery_time_interval_ms, :integer
      add :mana_recovery_time_amount, :decimal
      add :mana_recovery_damage_multiplier, :decimal
    end

    execute(
      """
      UPDATE characters
      SET base_mana = 100,
        initial_mana = 50,
        mana_recovery_strategy = 'time',
        mana_recovery_time_interval_ms = 1000,
        mana_recovery_time_amount = 1.0
      WHERE game_id = 1 AND mana_recovery_strategy IS NULL
      """, "")


    alter table(:skills) do
      add :mana_cost, :integer
      add :mana_recovery_amount, :integer
    end
  end
end

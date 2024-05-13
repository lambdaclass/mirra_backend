defmodule GameBackend.Repo.Migrations.AddDungeonSettlementLevel do
  use Ecto.Migration

  def change do
    create table(:dungeon_settlement_levels) do
      add(:level, :integer)
      add(:max_dungeon, :integer)
      add(:max_factional, :integer)
      add(:supply_limit, :integer)
      add(:level_up_costs, :map)
      timestamps()
    end

    alter table(:users) do
      add(:dungeon_settlement_level_id, references(:dungeon_settlement_levels, on_delete: :nothing))
      add(:last_dungeon_afk_reward_claim, :utc_datetime, default: fragment("now()"))
    end

    alter table(:afk_reward_rates) do
      add(:dungeon_settlement_level_id, references(:dungeon_settlement_levels, on_delete: :delete_all))
    end

    rename table(:users), :last_afk_reward_claim, to: :last_kaline_afk_reward_claim

    create unique_index(:dungeon_settlement_levels, [:level])
  end
end

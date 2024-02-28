defmodule GameBackend.Repo.Migrations.AddLevelRewards do
  use Ecto.Migration

  def change do
    alter table(:levels) do
      add :experience_reward, :integer
    end

    create table(:currency_rewards) do
      add :currency_id, references(:currencies, on_delete: :delete_all)
      add :level_id, references(:levels, on_delete: :delete_all)
      add :amount, :integer, null: false
      timestamps()
    end

    create table(:item_rewards) do
      add :item_id, references(:items, on_delete: :delete_all)
      add :level_id, references(:levels, on_delete: :delete_all)
      add :amount, :integer, null: false
      timestamps()
    end

    create table(:unit_rewards) do
      add :unit_id, references(:units, on_delete: :delete_all)
      add :level_id, references(:levels, on_delete: :delete_all)
      add :amount, :integer, null: false
      timestamps()
    end
  end
end

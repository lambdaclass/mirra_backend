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
      add :afk_reward, :boolean, null: :false
      timestamps()
    end

    create table(:item_rewards) do
      add :item_template_id, references(:item_templates, on_delete: :delete_all)
      add :item_level, :integer
      add :level_id, references(:levels, on_delete: :delete_all)
      add :amount, :integer, null: false
      timestamps()
    end

    create table(:unit_rewards) do
      add :character_id, references(:characters, on_delete: :delete_all)
      add :rank, :integer
      add :level_id, references(:levels, on_delete: :delete_all)
      add :amount, :integer, null: false
      timestamps()
    end
  end
end

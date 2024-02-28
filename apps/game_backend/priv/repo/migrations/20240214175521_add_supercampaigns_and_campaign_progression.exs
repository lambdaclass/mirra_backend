defmodule GameBackend.Repo.Migrations.AddCurrentCampaignAndLevelToUser do
  use Ecto.Migration

  def change do
    create table(:super_campaigns) do
      add :game_id, :integer, null: false
      add :name, :string, null: false
      timestamps()
    end

    create table(:campaigns) do
      add :game_id, :integer, null: false
      add :campaign_number, :integer
      add :super_campaign_id, references(:super_campaigns, on_delete: :delete_all)
      timestamps()
    end

    create table(:campaign_progressions) do
      add :game_id, :integer, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :level_id, references(:levels, on_delete: :delete_all)
      add :campaign_id, references(:campaigns, on_delete: :delete_all)
      timestamps()
    end

    alter table(:levels) do
      remove :campaign
      add :campaign_id, references(:campaigns, on_delete: :delete_all)
    end
  end
end

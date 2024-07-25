defmodule GameBackend.Repo.Migrations.AddSuperCampaignUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:super_campaigns, [:name, :game_id])
    create unique_index(:campaigns, [:campaign_number, :super_campaign_id])
  end
end

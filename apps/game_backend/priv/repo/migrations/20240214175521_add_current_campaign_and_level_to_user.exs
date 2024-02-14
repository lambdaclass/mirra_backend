defmodule GameBackend.Repo.Migrations.AddCurrentCampaignAndLevelToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :current_campaign, :integer, default: 1
      add :current_level, :integer, default: 1
    end
  end
end

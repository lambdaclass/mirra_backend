defmodule GameBackend.Campaigns.CampaignProgress do
  @moduledoc """
  Table to track the user's progress in a campaign.

  User can only have one CampaignProgress for every SuperCampaign, meaning they cannot be at
  Level 5 for Campaign 1 of a SuperCampaign and Level 2 for Campaign 2 of the same SuperCampaign.
  The progression would be: [1-5 -> 1-6 (last of campaign) -> 2-1]
  """
  # TODO: [CHoM-193] Refactor to SuperCampaignProgress
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Users.User

  use GameBackend.Schema
  import Ecto.Changeset

  schema "campaign_progresses" do
    field(:game_id, :integer)
    belongs_to(:user, User)
    belongs_to(:campaign, Campaign)
    belongs_to(:level, Level)

    timestamps()
  end

  @doc false
  def changeset(campaign_progress, attrs \\ %{}) do
    campaign_progress
    |> cast(attrs, [:game_id, :user_id, :campaign_id, :level_id])
    |> validate_required([:game_id, :user_id, :campaign_id, :level_id])
  end

  def advance_level_changeset(campaign_progress, attrs) do
    campaign_progress
    |> cast(attrs, [:level_id, :campaign_id])
    |> validate_required([:level_id, :campaign_id])
  end
end

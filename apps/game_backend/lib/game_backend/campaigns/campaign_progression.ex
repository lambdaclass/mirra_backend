defmodule GameBackend.Campaigns.CampaignProgress do
  @moduledoc """
  Table to track the user's progress in a campaign.
  """
  # TODO: [CHoM-193] Refactor to SuperCampaignProgress
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Users.User

  use GameBackend.Schema
  import Ecto.Changeset

  schema "campaign_progresss" do
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

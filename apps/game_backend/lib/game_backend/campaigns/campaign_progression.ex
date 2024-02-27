defmodule GameBackend.Campaigns.CampaignProgression do
  @moduledoc """
  Table to track the user's progress in a campaign.
  """
  # TODO: [CHoM-193] Refactor to SuperCampaignProgression
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Users.User

  use GameBackend.Schema
  import Ecto.Changeset

  schema "campaign_progressions" do
    field(:game_id, :integer)
    belongs_to(:user, User)
    belongs_to(:campaign, Campaign)
    belongs_to(:level, Level)

    timestamps()
  end

  @doc false
  def changeset(campaign_progression, attrs \\ %{}) do
    campaign_progression
    |> cast(attrs, [:game_id, :user_id, :campaign_id, :level_id])
    |> validate_required([:game_id, :user_id, :campaign_id, :level_id])
  end

  def advance_level_changeset(campaign_progression, attrs) do
    campaign_progression
    |> cast(attrs, [:level_id, :campaign_id])
    |> validate_required([:level_id, :campaign_id])
  end
end

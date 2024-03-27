defmodule GameBackend.Campaigns.SuperCampaignProgress do
  @moduledoc """
  Table to track the User's progress in a Campaign.

  User can only have one SuperCampaignProgress for every SuperCampaign, meaning they cannot be at
  Level 5 for Campaign 1 of a SuperCampaign and Level 2 for Campaign 2 of the same SuperCampaign.
  The progression would be: [1-5 -> 1-6 (last of Campaign) -> 2-1]
  """
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns.SuperCampaign
  alias GameBackend.Users.User

  use GameBackend.Schema
  import Ecto.Changeset

  schema "super_campaign_progresses" do
    field(:game_id, :integer)
    belongs_to(:user, User)
    belongs_to(:super_campaign, SuperCampaign)
    belongs_to(:level, Level)

    timestamps()
  end

  @doc false
  def changeset(super_campaign_progress, attrs \\ %{}) do
    super_campaign_progress
    |> cast(attrs, [:game_id, :user_id, :super_campaign_id, :level_id])
    |> validate_required([:game_id, :user_id, :super_campaign_id, :level_id])
  end

  def advance_level_changeset(super_campaign_progress, attrs) do
    super_campaign_progress
    |> cast(attrs, [:level_id, :super_campaign_id])
    |> validate_required([:level_id, :super_campaign_id])
  end
end

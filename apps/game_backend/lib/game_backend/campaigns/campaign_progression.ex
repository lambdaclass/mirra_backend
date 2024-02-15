defmodule GameBackend.Campaigns.CampaignProgression do
  @moduledoc """
  Campaign Progression
  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "campaign_progressions" do
    field(:game_id, :integer)
    field(:user_id, :binary_id)
    field(:campaign_id, :binary_id)
    field(:level_id, :binary_id)

    timestamps()
  end

  @doc false
  def changeset(campaign_progression, attrs \\ %{}) do
    campaign_progression
    |> cast(attrs, [:game_id, :user_id, :campaign_id, :level_id])
    |> validate_required([:game_id, :user_id, :campaign_id, :level_id])
  end
end

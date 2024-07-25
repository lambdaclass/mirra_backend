defmodule GameBackend.Campaigns.Campaign do
  @moduledoc """
  Campaigns
  """
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns.SuperCampaign
  use GameBackend.Schema
  import Ecto.Changeset

  schema "campaigns" do
    field(:game_id, :integer)
    field(:campaign_number, :integer)

    belongs_to(:super_campaign, SuperCampaign)
    has_many(:levels, Level)

    timestamps()
  end

  @doc false
  def changeset(campaign, attrs \\ %{}) do
    campaign
    |> cast(attrs, [:game_id, :campaign_number, :super_campaign_id])
    |> cast_assoc(:levels)
    |> validate_required([:game_id, :super_campaign_id])
    |> unique_constraint([:campaign_number, :super_campaign_id])
  end
end

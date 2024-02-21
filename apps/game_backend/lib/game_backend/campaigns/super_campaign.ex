defmodule GameBackend.Campaigns.SuperCampaign do
  @moduledoc """
  SuperCampaign
  """
  alias GameBackend.Campaigns.Campaign

  use GameBackend.Schema
  import Ecto.Changeset

  schema "super_campaigns" do
    field(:game_id, :integer)
    field(:name, :string)

    has_many(:campaigns, Campaign)

    timestamps()
  end

  @doc false
  def changeset(super_campaign, attrs \\ %{}) do
    super_campaign
    |> cast(attrs, [:game_id, :name])
    |> cast_assoc(:campaigns)
    |> validate_required([:game_id])
  end
end

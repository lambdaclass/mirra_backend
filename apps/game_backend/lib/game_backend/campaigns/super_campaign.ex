defmodule GameBackend.Campaigns.SuperCampaign do
  @moduledoc """
  SuperCampaigns are sequential collections of Campaigns.
  A user may only be on one Campaign of a SuperCampaign at the same time.
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
    |> unique_constraint([:name, :game_id])
  end
end

defmodule GameBackend.Campaigns.Campaign do
  @moduledoc """
  Campaigns
  """

  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id]}
  schema "campaigns" do
    field(:game_id, :integer)
    field(:campaign_id, :integer)

    has_many(:levels, Level)

    timestamps()
  end

  @doc false
  def changeset(campaign, attrs \\ %{}) do
    campaign
    |> cast(attrs, [:game_id, :campaign_id, :levels])
    |> validate_required([:game_id, :campaign_id, :levels])
  end
end

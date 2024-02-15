defmodule GameBackend.Campaigns.Campaign do
  @moduledoc """
  Campaigns
  """
  alias GameBackend.Campaigns.Level
  alias GameBackend.Campaigns.Quest
  use GameBackend.Schema
  import Ecto.Changeset

  schema "campaigns" do
    field(:game_id, :integer)
    field(:campaign_number, :integer)

    belongs_to(:quest, Quest)
    has_many(:levels, Level)

    timestamps()
  end

  @doc false
  def changeset(campaign, attrs \\ %{}) do
    campaign
    |> cast(attrs, [:game_id, :campaign_number, :quest_id])
    |> cast_assoc(:levels)
    |> validate_required([:game_id, :quest_id])
  end
end

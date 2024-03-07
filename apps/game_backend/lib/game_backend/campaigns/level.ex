defmodule GameBackend.Campaigns.Level do
  @moduledoc """
  Levels
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Units.Unit

  schema "levels" do
    field(:game_id, :integer)
    field(:level_number, :integer)

    belongs_to(:campaign, Campaign)
    has_many(:units, Unit, foreign_key: :campaign_level_id)

    timestamps()
  end

  @doc false
  def changeset(level, attrs \\ %{}) do
    level
    |> cast(attrs, [:game_id, :level_number, :campaign_id])
    |> cast_assoc(:units)
    |> validate_required([:game_id, :level_number, :campaign_id])
  end
end

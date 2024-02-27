defmodule GameBackend.Campaigns.Level do
  @moduledoc """
  Levels
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Campaigns.Campaign
  alias GameBackend.Units.Unit

  @derive {Jason.Encoder, only: [:id, :level_number, :campaign, :units]}
  schema "levels" do
    field(:game_id, :integer)
    field(:level_number, :integer)

    belongs_to(:campaign, Campaign)
    has_many(:units, Unit)

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

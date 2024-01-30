defmodule GameBackend.Campaigns.Level do
  @moduledoc """
  Levels
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Units.Unit

  @derive {Jason.Encoder, only: [:id, :level_number, :campaign, :units]}
  schema "levels" do
    field(:game_id, :integer)
    field(:level_number, :integer)
    field(:campaign, :integer)

    has_many(:units, Unit)

    timestamps()
  end

  @doc false
  def changeset(level, attrs \\ %{}) do
    level
    |> cast(attrs, [:game_id, :level_number, :campaign])
    |> cast_assoc(:units)
    |> validate_required([:game_id, :level_number, :campaign])
  end

  @doc """
  Changeset for editing a level's basic attributes.
  """
  def edit_changeset(level, attrs), do: cast(level, attrs, [:campaign])
end

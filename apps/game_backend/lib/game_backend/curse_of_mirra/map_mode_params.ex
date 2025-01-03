defmodule GameBackend.CurseOfMirra.MapModeParams do
  @moduledoc """
  MapModeParams schema

  Stores all params related to a specific game mode in a specific map.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.CurseOfMirra.MapConfiguration
  alias GameBackend.CurseOfMirra.GameModeConfiguration

  @derive {Jason.Encoder, only: [:amount_of_players, :initial_positions]}

  schema "map_mode_params" do
    field(:amount_of_players, :integer)
    embeds_many(:initial_positions, InitialPosition)

    belongs_to(:map, MapConfiguration, foreign_key: :map_id)
    belongs_to(:game_mode, GameModeConfiguration, foreign_key: :game_mode_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(map_mode_params, attrs) do
    map_mode_params
    |> cast(attrs, [:amount_of_players, :map_id, :game_mode_id])
    |> validate_required([:amount_of_players])
    |> cast_embed(:initial_positions)
  end

  defmodule InitialPosition do
    @moduledoc """
    InitialPosition embedded schema to be used by MapModeParams.

    Stores the players' positions for team/solo modes.
    """
    use GameBackend.Schema

    @derive {Jason.Encoder, only: [:type, :positions]}
    embedded_schema do
      field(:type, Ecto.Enum, values: [:solo, :team])
      embeds_many(:positions, Position)
    end

    def changeset(initial_position, attrs) do
      initial_position
      |> cast(attrs, [:type])
      |> validate_required([:type])
      |> cast_embed(attrs, [:positions])
    end
  end

  defmodule Position do
    @moduledoc """
    Position embedded schema to be used by MapModeParams
    """
    use GameBackend.Schema

    @derive {Jason.Encoder, only: [:x, :y]}
    embedded_schema do
      field(:x, :decimal)
      field(:y, :decimal)
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [:x, :y])
      |> validate_required([:x, :y])
    end
  end
end

defmodule GameBackend.CurseOfMirra.MapModeParams do
  @moduledoc """
  MapModeParams schema

  Stores all params related to a specific game mode in a specific map.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.CurseOfMirra.MapConfiguration
  alias GameBackend.CurseOfMirra.GameModeConfiguration
  alias GameBackend.CurseOfMirra.Position

  @derive {Jason.Encoder, only: [:amount_of_players, :solo_initial_positions, :team_initial_positions]}

  schema "map_mode_params" do
    field(:amount_of_players, :integer)
    embeds_many(:solo_initial_positions, Position, on_replace: :delete)
    embeds_many(:team_initial_positions, Position, on_replace: :delete)

    belongs_to(:map, MapConfiguration, foreign_key: :map_id)
    belongs_to(:game_mode, GameModeConfiguration, foreign_key: :game_mode_id)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(map_mode_params, attrs) do
    map_mode_params
    |> cast(attrs, [:amount_of_players, :map_id, :game_mode_id])
    |> validate_required([:map_id, :game_mode_id, :amount_of_players])
    |> cast_embed(:solo_initial_positions)
    |> cast_embed(:team_initial_positions)
  end

  @doc false
  def assoc_changeset(map_mode_params, attrs) do
    map_mode_params
    |> cast(attrs, [:amount_of_players, :map_id, :game_mode_id])
    |> validate_required([:map_id, :amount_of_players])
    |> cast_embed(:solo_initial_positions)
    |> cast_embed(:team_initial_positions)
  end
end

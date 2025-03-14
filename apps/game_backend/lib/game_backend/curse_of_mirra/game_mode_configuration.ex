defmodule GameBackend.CurseOfMirra.GameModeConfiguration do
  @moduledoc """
  GameModeConfiguration schema

  Stores all params related to a specific game mode.
  """
  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Configuration.Version
  alias GameBackend.CurseOfMirra.MapModeParams

  @derive {Jason.Encoder,
           only: [
             :type,
             :zone_enabled,
             :bots_enabled,
             :match_duration_ms,
             :respawn_time_ms,
             :map_mode_params,
             :team_size
           ]}

  schema "game_mode_configurations" do
    field(:type, Ecto.Enum, values: [:battle_royale, :deathmatch, :practice])
    field(:zone_enabled, :boolean)
    field(:bots_enabled, :boolean)
    field(:match_duration_ms, :integer)
    field(:deleted_at, :naive_datetime)

    # Team modes parameters
    field(:team_size, :integer)

    # Deathmatch mode parameters
    field(:respawn_time_ms, :integer)

    has_many(:map_mode_params, MapModeParams, foreign_key: :game_mode_id, on_replace: :delete)
    belongs_to(:version, Version)

    timestamps(type: :utc_datetime)
  end

  @required [:type, :version_id, :bots_enabled, :zone_enabled]
  @permitted [
               :type,
               :zone_enabled,
               :bots_enabled,
               :match_duration_ms,
               :respawn_time_ms,
               :version_id,
               :team_size
             ] ++
               @required

  @doc false
  def changeset(game_mode_configuration, attrs) do
    game_mode_configuration
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> cast_assoc(:map_mode_params, with: &MapModeParams.assoc_changeset/2)
  end

  @doc false
  def delete_changeset(game_mode_configuration, attrs) do
    game_mode_configuration
    |> cast(attrs, [:deleted_at])
    |> validate_required([:deleted_at])
  end
end

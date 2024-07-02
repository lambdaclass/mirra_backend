defmodule GameBackend.CurseOfMirra.GameConfiguration do
  @moduledoc """
  GameConfiguration schema
  """
  use GameBackend.Schema
  import Ecto.Changeset

  schema "game_configurations" do
    field(:tick_rate_ms, :integer)
    field(:bounty_pick_time_ms, :integer)
    field(:start_game_time_ms, :integer)
    field(:end_game_interval_ms, :integer)
    field(:shutdown_game_wait_ms, :integer)
    field(:natural_healing_interval_ms, :integer)
    field(:zone_shrink_start_ms, :integer)
    field(:zone_shrink_radius_by, :integer)
    field(:zone_shrink_interval, :integer)
    field(:zone_stop_interval_ms, :integer)
    field(:zone_start_interval_ms, :integer)
    field(:zone_damage_interval_ms, :integer)
    field(:zone_damage, :integer)
    field(:item_spawn_interval_ms, :integer)
    field(:bots_enabled, :boolean)
    field(:zone_enabled, :boolean)
    field(:bounties_options_amount, :integer)

    timestamps()
  end

  @required [
    :tick_rate_ms,
    :bounty_pick_time_ms,
    :start_game_time_ms,
    :end_game_interval_ms,
    :shutdown_game_wait_ms,
    :natural_healing_interval_ms,
    :zone_shrink_start_ms,
    :zone_shrink_radius_by,
    :zone_shrink_interval,
    :zone_stop_interval_ms,
    :zone_start_interval_ms,
    :zone_damage_interval_ms,
    :zone_damage,
    :item_spawn_interval_ms,
    :bots_enabled,
    :zone_enabled,
    :bounties_options_amount
  ]
  @doc false
  def changeset(game_configuration, attrs) do
    game_configuration
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end

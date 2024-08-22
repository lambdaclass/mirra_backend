defmodule GameBackend.CurseOfMirra.GameConfiguration do
  @moduledoc """
  GameConfiguration schema
  """
  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Configuration.Version

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
    :bounties_options_amount,
    :match_timeout_ms,
    :field_of_view_inside_bush,
    :time_visible_in_bush_after_skill,
    :version_id,
    :zone_start_radius,
    :zone_random_position_radius,
    :distance_to_power_up,
    :power_up_damage_modifier,
    :power_up_health_modifier,
    :power_up_radius,
    :power_up_activation_delay_ms
  ]

  @derive {Jason.Encoder, only: @required ++ [:power_ups_per_kill]}
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
    field(:match_timeout_ms, :integer)
    field(:field_of_view_inside_bush, :integer)
    field(:time_visible_in_bush_after_skill, :integer)
    field(:zone_start_radius, :float)
    field(:zone_random_position_radius, :integer)
    field(:distance_to_power_up, :integer)
    field(:power_up_damage_modifier, :float)
    field(:power_up_health_modifier, :float)
    field(:power_up_radius, :float)
    field(:power_up_activation_delay_ms, :integer)

    embeds_many(:power_ups_per_kill, __MODULE__.PowerUpPerKillAmount)

    belongs_to(:version, Version)

    timestamps()
  end

  @doc false
  def changeset(game_configuration, attrs) do
    game_configuration
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_embed(:power_ups_per_kill)
  end

  defmodule PowerUpPerKillAmount do
    @moduledoc """
    Position embedded schema to be used by MapConfiguration
    """
    use GameBackend.Schema

    @derive {Jason.Encoder, only: [:minimum_amount_of_power_ups, :amount_of_power_ups_to_drop]}
    embedded_schema do
      field(:minimum_amount_of_power_ups, :integer)
      field(:amount_of_power_ups_to_drop, :integer)
    end

    def changeset(position, attrs) do
      position
      |> cast(attrs, [:minimum_amount_of_power_ups, :amount_of_power_ups_to_drop])
      |> validate_required([:minimum_amount_of_power_ups, :amount_of_power_ups_to_drop])
    end
  end
end

defmodule Configurator.Configuration.GameConfig do
  use Configurator.Schema
  import Ecto.Changeset

  schema "game_configurations" do
    field :end_game_interval_ms, :integer
    field :item_spawn_interval_ms, :integer
    field :natural_healing_interval_ms, :integer
    field :shutdown_game_wait_ms, :integer
    field :start_game_time_ms, :integer
    field :tick_rate_ms, :integer
    field :zone_damage_interval_ms, :integer
    field :zone_damage, :integer
    field :zone_shrink_interval, :integer
    field :zone_shrink_radius_by, :integer
    field :zone_shrink_start_ms, :integer
    field :zone_start_interval_ms, :integer
    field :zone_stop_interval_ms, :integer

    timestamps(type: :utc_datetime)
  end

  @required [
    :end_game_interval_ms, :item_spawn_interval_ms, :natural_healing_interval_ms, :shutdown_game_wait_ms, :start_game_time_ms, :tick_rate_ms, :zone_damage_interval_ms, :zone_damage, :zone_shrink_interval, :zone_shrink_radius_by, :zone_shrink_start_ms, :zone_start_interval_ms, :zone_stop_interval_ms
  ]

  @doc false
  def changeset(game_config, attrs) do
    game_config
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> validate_number_all_fields(greater_than_or_equal_to: 0)
  end

  defp validate_number_all_fields(changeset, opts) do
    Enum.reduce(@required, changeset, fn field, changeset ->
      validate_number(changeset, field, opts)
    end)
  end
end

defmodule DarkWorldsServer.Config.Games.ZoneModification do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Config.Characters.Effect
  alias DarkWorldsServer.Config.Games.Game
  alias DarkWorldsServer.Config.Games.ZoneModificationEffect

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "zone_modifications" do
    field(:duration_ms, :integer)
    field(:interval_ms, :integer)
    field(:min_radius, :integer)
    field(:max_radius, :integer)
    field(:modifier, :string)
    field(:value, :float)

    # Needed to create the association table later
    field(:effect_names, {:array, :string})
    many_to_many(:outside_radius_effects, Effect, join_through: ZoneModificationEffect)

    belongs_to(:game, Game)

    timestamps()
  end

  @doc false
  def changeset(zone_modification, attrs),
    do:
      zone_modification
      |> cast(attrs, [:duration_ms, :interval_ms, :min_radius, :max_radius])
      |> cast_modifier_and_value(attrs.modification)
      |> cast_effect_names(attrs)
      |> validate_required([:duration_ms, :interval_ms, :min_radius, :max_radius, :modifier, :value])

  defp cast_modifier_and_value(changeset, {modifier, value})
       when modifier in [:additive, :multiplicative],
       do: cast(changeset, %{modifier: Atom.to_string(modifier), value: value}, [:modifier, :value])

  defp cast_effect_names(changeset, %{outside_radius_effects: []}), do: changeset

  defp cast_effect_names(changeset, %{outside_radius_effects: effects}),
    do: cast(changeset, %{effect_names: Enum.map(effects, & &1.name)}, [:effect_names])

  def to_backend_map(zone_modification),
    do: %{
      duration_ms: zone_modification.duration_ms,
      interval_ms: zone_modification.interval_ms,
      max_radius: zone_modification.max_radius,
      min_radius: zone_modification.min_radius,
      outside_radius_effects: Enum.map(zone_modification.outside_radius_effects, &Effect.to_backend_map/1),
      modification: adapt_modification(zone_modification.modifier, zone_modification.value)
    }

  # Rust enum value type differs based on modifier type
  defp adapt_modification("additive", value), do: {:additive, trunc(value)}
  defp adapt_modification("multiplicative", value), do: {:multiplicative, value}
end

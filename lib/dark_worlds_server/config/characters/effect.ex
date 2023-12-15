defmodule DarkWorldsServer.Config.Characters.Effect do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Config.Characters.Effect.AttributesModifier
  alias DarkWorldsServer.Config.Characters.TimeType

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "effects" do
    field(:name, :string)
    field(:is_reversable, :boolean)
    # We do it like this instead of a relation because the backend needs only the number, not the whole struct.
    field(:skills_keys_to_execute, {:array, :string})
    field(:effect_time_type, TimeType)
    embeds_many(:player_attributes, AttributesModifier)
    embeds_many(:projectile_attributes, AttributesModifier)

    timestamps()
  end

  @doc false
  def changeset(effect, attrs) do
    effect
    |> cast(attrs, [:name, :is_reversable, :skills_keys_to_execute, :effect_time_type])
    |> cast_embed(:player_attributes)
    |> cast_embed(:projectile_attributes)
    |> validate_required([
      :name,
      :is_reversable,
      :effect_time_type
    ])
  end

  def to_backend_map(effect),
    do: %{
      name: "damage_outside_area",
      projectile_attributes: Enum.map(effect.projectile_attributes, &AttributesModifier.to_backend_map/1),
      player_attributes: Enum.map(effect.player_attributes, &AttributesModifier.to_backend_map/1),
      effect_time_type: effect.effect_time_type,
      is_reversable: effect.is_reversable,
      skills_keys_to_execute: effect.skills_keys_to_execute
    }

  defmodule AttributesModifier do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:attribute, :string)
      field(:modifier, :string)
      field(:value, :string)
    end

    def changeset(attributes_modifier, attrs) do
      attributes_modifier
      |> cast(attrs, [:attribute, :modifier, :value])
      |> validate_inclusion(:modifier, ["additive", "multiplicative", "override"])
      |> validate_required([:attribute, :modifier, :value])
    end

    def to_backend_map(attributes_modifier),
      do: %{
        attribute: attributes_modifier.attribute,
        modifier: String.to_atom(attributes_modifier.modifier),
        value: attributes_modifier.value
      }
  end
end

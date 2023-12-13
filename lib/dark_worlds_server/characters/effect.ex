defmodule DarkWorldsServer.Effect do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.TimeType

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "effects" do
    field(:name, :string)
    field(:is_reversable, :boolean)
    field(:effect_time_type, TimeType)
    embeds_many(:player_attributes, AttributesModifier)
    embeds_many(:projectile_attributes, AttributesModifier)
    embeds_many(:skills_keys_to_execute, :string)

    timestamps()
  end

  @doc false
  def changeset(effect, attrs) do
    effect
    |> cast(attrs, [:name, :is_reversable, :skills_keys_to_execute])
    |> cast_embed(:player_attributes)
    |> cast_embed(:projectile_attributes)
    |> cast_time_type(attrs[:effect_time_type])
    |> validate_required([
      :name,
      :is_reversable,
      :effect_time_type,
      :player_attributes,
      :projectile_attributes,
      :skills_keys_to_execute
    ])
  end

  defp cast_time_type(changeset, value) do
    cast(changeset, %{effect_time_type: TimeType.to_string(value)}, [:effect_time_type])
  end

  defmodule AttributesModifier do
    use Ecto.Schema

    embedded_schema do
      field(:attribute, :string)
      field(:modifier, :string)
      field(:value, :string)
    end

    def changeset(attributes_modifier, attrs) do
      attributes_modifier
      |> cast(attrs, [:attribute, :modifier, :value])
    end
  end
end

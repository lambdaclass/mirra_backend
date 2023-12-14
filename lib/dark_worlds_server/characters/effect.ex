defmodule DarkWorldsServer.Characters.Effect do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Characters.Effect.AttributesModifier
  alias DarkWorldsServer.Characters.TimeType

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "effects" do
    field(:name, :string)
    field(:is_reversable, :boolean)
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
    end
  end
end

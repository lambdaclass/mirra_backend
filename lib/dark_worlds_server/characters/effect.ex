defmodule DarkWorldsServer.Effect do
  use Ecto.Schema
  import Ecto.Changeset
  alias DarkWorldsServer.Effect.AttributesModifier
  alias DarkWorldsServer.EffectSkill
  alias DarkWorldsServer.Skill
  alias DarkWorldsServer.TimeType

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "effects" do
    field(:name, :string)
    field(:is_reversable, :boolean)
    field(:effect_time_type, TimeType)
    embeds_many(:player_attributes, AttributesModifier)
    embeds_many(:projectile_attributes, AttributesModifier)

    has_many(:skills_to_execute, EffectSkill)

    timestamps()
  end

  @doc false
  def changeset(effect, attrs) do
    effect
    |> cast(attrs, [:name, :is_reversable])
    |> cast_embed(:player_attributes)
    |> cast_embed(:projectile_attributes)
    |> cast_time_type(attrs[:effect_time_type])
    |> IO.inspect(label: :changeset_after_casts)
    |> validate_required([
      :name,
      :is_reversable,
      :effect_time_type
    ])
  end

  defp cast_time_type(changeset, value) do
    cast(changeset, %{effect_time_type: value}, [:effect_time_type])
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

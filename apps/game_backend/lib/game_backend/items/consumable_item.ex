defmodule GameBackend.Items.ConsumableItem do
  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Effects.ConfigurationEffect

  @derive {Jason.Encoder, only: [:name, :radius, :effects]}
  schema "consumable_items" do
    field(:name, :string)
    field(:radius, :float)

    has_many(:effects, ConfigurationEffect)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(consumable_item, attrs) do
    consumable_item
    |> cast(attrs, [:name, :radius])
    |> cast_assoc(:effects, with: &ConfigurationEffect.changeset/2)
    |> validate_required([:name, :radius])
  end
end

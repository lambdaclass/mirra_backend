defmodule GameBackend.Items.ConsumableItem do
  @moduledoc """
  ConsumableItem schema
  """
  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Effects.ConfigurationEffect

  @derive {Jason.Encoder, only: [:name, :radius, :effects, :mechanics]}
  schema "consumable_items" do
    field(:active, :boolean, default: false)
    field(:name, :string)
    field(:radius, :float)
    field(:mechanics, {:map, :map})

    has_many(:effects, ConfigurationEffect, on_replace: :delete)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(consumable_item, attrs) do
    consumable_item
    |> cast(attrs, [:name, :radius, :mechanics, :active])
    |> cast_assoc(:effects, with: &ConfigurationEffect.changeset/2)
    |> validate_required([:name, :radius])
  end
end

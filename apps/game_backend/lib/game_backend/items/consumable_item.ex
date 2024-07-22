defmodule GameBackend.Items.ConsumableItem do
  @moduledoc """
  ConsumableItem schema
  """
  use GameBackend.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:name, :radius, :effects, :mechanics]}
  schema "consumable_items" do
    field(:active, :boolean, default: false)
    field(:name, :string)
    field(:radius, :float)
    field(:effects, {:array, :string})
    field(:mechanics, {:map, :map})

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(consumable_item, attrs) do
    consumable_item
    |> cast(attrs, [:name, :radius, :mechanics, :active, :effects])
    |> validate_required([:name, :radius])
  end
end

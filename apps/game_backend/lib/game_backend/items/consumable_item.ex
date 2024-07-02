defmodule GameBackend.Items.ConsumableItem do
  use GameBackend.Schema
  import Ecto.Changeset

  schema "consumable_items" do
    field(:name, :string)
    field(:radius, :float)
    field(:effects, {:array, :string})

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(consumable_item, attrs) do
    consumable_item
    |> cast(attrs, [:name, :radius, :effects])
    |> validate_required([:name, :radius, :effects])
  end
end

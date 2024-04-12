defmodule GameBackend.Items.ItemTemplate do
  @moduledoc """
  ItemTemplates are the template on which items are based.
  """
  alias GameBackend.Items.BaseModifier

  use GameBackend.Schema
  import Ecto.Changeset

  schema "item_templates" do
    field(:game_id, :integer)
    field(:name, :string)
    field(:type, :string)
    embeds_many(:base_modifiers, BaseModifier)

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:game_id, :name, :type])
    |> cast_embed(:base_modifiers)
    |> validate_required([:game_id, :name, :type])
  end
end

defmodule GameBackend.Items.ItemTemplate do
  @moduledoc """
  ItemTemplates are the template on which items are based.
  Type is the category of the item, such as "weapon", "helmet", "boots", etc.
  BaseModifiers are the modifiers that are applied to the character when the item is equipped.

  ## Examples
      # ItemTemplate to create a sword that increments attack by 30%:
      %ItemTemplate{
        game_id: 2,
        name: "Sword",
        type: "weapon",
        base_modifiers: [
          %BaseModifier{
            attribute: "attack",
            modifier_operation: "Multiply",
            base_value: 1.3
          }
        ]
      }
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

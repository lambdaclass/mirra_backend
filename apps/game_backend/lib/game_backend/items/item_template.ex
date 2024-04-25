defmodule GameBackend.Items.ItemTemplate do
  @moduledoc """
  ItemTemplates are the template on which items are based.
  Type is the category of the item, such as "weapon", "helmet", "boots", etc.
  Modifiers are the modifiers that are applied to the character when the item is equipped.

  ## Examples
      # ItemTemplate to create a sword that increments attack by 30%:
      %ItemTemplate{
        game_id: 2,
        name: "Sword",
        type: "weapon",
        base_modifiers: [
          %Modifier{
            attribute: "attack",
            operation: "Multiply",
            base_value: 1.3
          }
        ]
      }
  """
  alias GameBackend.Items.Modifier
  alias GameBackend.Users.Currencies.CurrencyCost

  use GameBackend.Schema
  import Ecto.Changeset

  schema "item_templates" do
    field(:game_id, :integer)
    field(:name, :string)
    field(:rarity, :integer)
    field(:type, :string)
    embeds_many(:modifiers, Modifier, on_replace: :delete)

    # Used to reference the ItemTemplate in the game's configuration
    field(:config_id, :string)

    belongs_to(:upgrades_from, __MODULE__, foreign_key: :upgrades_from_config_id, references: :config_id, type: :string)
    field(:upgrades_from_quantity, :integer)
    embeds_many(:upgrade_costs, CurrencyCost, on_replace: :delete)

    timestamps()
  end

  @doc false
  def changeset(item_template, attrs) do
    item_template
    |> cast(attrs, [:game_id, :name, :rarity, :type, :config_id, :upgrades_from_config_id, :upgrades_from_quantity])
    |> validate_required([:game_id, :name, :rarity, :type, :config_id])
    |> cast_embed(:modifiers)
    |> cast_embed(:upgrade_costs)
    |> foreign_key_constraint(:upgrades_from_config_id)
  end
end

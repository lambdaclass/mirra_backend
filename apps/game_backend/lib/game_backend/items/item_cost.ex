defmodule GameBackend.Items.ItemCost do
  @moduledoc """
  Contains a set the different prices to purchase an ItemTemplate.
  """
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Items.ItemTemplate

  use GameBackend.Schema
  import Ecto.Changeset

  schema "item_costs" do
    field(:name, :string)
    belongs_to(:item_template, ItemTemplate)
    embeds_many(:currency_costs, CurrencyCost)

    timestamps()
  end

  @doc false
  def changeset(item_template, attrs) do
    item_template
    |> cast(attrs, [:item_template_id, :name])
    |> cast_embed(:currency_costs)
    |> validate_required([:name])
  end
end

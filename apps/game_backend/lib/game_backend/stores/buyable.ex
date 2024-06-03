defmodule GameBackend.Stores.Buyable do
  @moduledoc """
  Buyable is anything that can be purchased in a Store.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Stores.Store
  alias GameBackend.Items.ItemTemplate
  alias GameBackend.User.Currencies.Currency
  alias GameBackend.User.Currencies.CurrencyCost

  schema "buyables" do
    field(:name, :string)
    field(:stock, :integer)
    field(:amount, :integer)
    embeds_many(:purchase_costs, CurrencyCost, on_replace: :delete)
    belongs_to(:store, Store, on_replace: :delete)
    has_one(:currency, Currency)
    has_one(:item_template, ItemTemplate)

    timestamps()
  end

  @doc false
  def changeset(store, attrs) do
    store
    |> cast(attrs, [:name, :stock, :amount, :end_date, :store_id])
    |> cast_embed(:purchase_costs)
    |> validate_required([:name, :stock, :amount])
    |> cast_assoc(:items)
  end
end

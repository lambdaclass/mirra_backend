defmodule GameBackend.Stores do
  @moduledoc """
  Store operations.
  """
  alias GameBackend.Stores.Store
  alias GameBackend.Repo

  @doc """
  Inserts a Store.
  """
  def insert_store(attrs) do
    %Store{}
    |> Store.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get Store by name.
  """
  def get_store_by_name(name) do
    case Repo.get_by(Store, name: name) do
      nil -> {:error, :not_found}
      store -> {:ok, store}
    end
  end

  @doc """
  Returns {:ok, :available} if we are within Store dates.
  Returns {:error, :not_available} otherwise.
  """
  def is_active(store) do
    now = DateTime.utc_now()

    if (is_nil(store.start_date) or store.start_date <= now) and store.end_date >= now do
      {:ok, :active}
    else
      {:error, :not_active}
    end
  end

  def list_items_with_prices(store) do
    store = Repo.preload(store, items: [item_costs: [currency_costs: :currency]])

    Enum.flat_map(store.items, fn item ->
      Enum.map(item.item_costs, fn item_cost ->
        {item.name,
         Enum.map(item_cost.currency_costs, fn currency_cost -> {currency_cost.currency.name, currency_cost.amount} end)}
      end)
    end)
  end
end

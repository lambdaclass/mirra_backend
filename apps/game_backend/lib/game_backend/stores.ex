defmodule GameBackend.Stores do
  @moduledoc """
  Store operations.
  """
  alias GameBackend.Stores.Store
  alias GameBackend.Items.ItemTemplate
  alias GameBackend.Repo
  import Ecto.Query

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
    store = Repo.preload(store, items: [purchase_costs: :currency])

    Enum.flat_map(store.items, fn item ->
      Enum.map(item.purchase_costs, fn purchase_cost ->
        %{item.name => %{purchase_cost.currency.name => purchase_cost.amount}}
      end)
    end)
  end

  def item_in_store(item_name, store_id, game_id) do
    case Repo.exists?(
           from(it in ItemTemplate,
             where: it.name == ^item_name and it.store_id == ^store_id and it.game_id == ^game_id
           )
         ) do
      false -> {:error, :not_found}
      true -> {:ok, :item_in_store}
    end
  end
end

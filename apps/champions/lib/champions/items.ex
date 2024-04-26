defmodule Champions.Items do
  @moduledoc """
  Items logic for Champions of Mirra.
  """

  alias GameBackend.Items
  alias GameBackend.Users.Currencies

  @doc """
  Get an item by id.
  """
  def get_item(item_id), do: Items.get_item(item_id)

  @doc """
  Get all items owned by a user.
  """
  def get_items(user_id), do: Items.get_items(user_id)

  @doc """
  Level up a user's item and substracts the currency cost from the user.

  Returns `{:error, :not_found}` if item doesn't exist or if it's not owned by user.
  Returns `{:error, :cant_afford}` if user cannot afford the cost.
  Returns `{:ok, item: %Item{}, user_currency: %UserCurrency{}}` if succesful.
  """
  def level_up(user_id, item_id) do
    with {:item, {:ok, item}} <- {:item, Items.get_item(item_id)},
         {:item_owned, true} <- {:item_owned, item.user_id == user_id},
         [{level_up_currency_id, level_up_cost}] = calculate_level_up_cost(item),
         {:can_afford, true} <-
           {:can_afford, Currencies.can_afford(user_id, level_up_currency_id, level_up_cost)} do
      Items.level_up(item, level_up_currency_id, level_up_cost)
    else
      {:item, {:error, :not_found}} -> {:error, :not_found}
      {:item_owned, false} -> {:error, :not_found}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  def equip_item(user_id, item_id, unit_id) do
    Items.equip_item(user_id, item_id, unit_id)
    get_item(item_id)
  end

  def unequip_item(user_id, item_id) do
    Items.unequip_item(user_id, item_id)
    get_item(item_id)
  end

  defp calculate_level_up_cost(item),
    do: [{Currencies.get_currency_by_name!("Gold").id, item.level |> Math.pow(2) |> round()}]
end

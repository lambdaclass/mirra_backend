defmodule Champions.Items do
  @moduledoc """
  Items logic for Champions of Mirra.
  """

  alias GameBackend.Items
  alias GameBackend.Users.Currencies

  @doc """
  Get an item by id.
  """
  def get_item(item_id) do
    case Items.get_item(item_id) do
      {:ok, item} -> item
      error -> error
    end
  end

  @doc """
  Level up a user's item and substracts the currency cost from the user.

  Returns :not_found if item doesn't exist or if it's not owned by user.
  Returns :cant_afford if user cannot afford the cost.
  Returns :ok if succesful.
  """
  def level_up(user_id, item_id) do
    {:ok, item} = Items.get_item(item_id) || %{}

    if Map.get(item, :user_id, nil) == user_id do
      {level_up_currency_id, level_up_cost} = calculate_level_up_cost(item)

      if Currencies.can_afford(user_id, level_up_currency_id, level_up_cost) do
        case Items.level_up(item) do
          {:ok, _item} ->
            Currencies.add_currency(user_id, level_up_currency_id, -level_up_cost)
            item = get_item(item_id)
            {:ok, item}

          {:error, error} ->
            {:error, error}
        end
      else
        {:error, :cant_afford}
      end
    else
      {:error, :not_found}
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
    do: {Currencies.get_currency_by_name!("Gold").id, item.level |> Math.pow(2) |> round()}
end

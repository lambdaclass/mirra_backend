defmodule Champions.Items do
  @moduledoc """
  Items logic for Champions of Mirra.
  """

  alias Ecto.Multi
  alias GameBackend.Items
  alias GameBackend.Transaction
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
  Equip an item to a unit. Unequips the previously eqyupped item of the same type if there is any.
  """
  def equip_item(user_id, item_id, unit_id) do
    Items.equip_item_and_unequip_previous(user_id, item_id, unit_id)
    get_item(item_id)
  end

  @doc """
  Unequip an item from a unit.
  """
  def unequip_item(user_id, item_id) do
    Items.unequip_item(user_id, item_id)
    get_item(item_id)
  end

  @doc """
  Consume a list of items that meet specific rank and character requirements based on the target
  item in order to increase its tier. Unlike Units, Items don't have a tier. Instead, we create a new
  one with the improved ItemTemplate.

  Returns `{:ok, item}` or `{:error, reason}`.
  """
  def fuse(user_id, consumed_items_ids) do
    with consumed_items <- Items.get_items_by_ids(consumed_items_ids),
         {:consumed_items_owned, true} <-
           {:consumed_items_owned, Enum.all?(consumed_items, &(&1.user_id == user_id))},
         {:consumed_items_count, true} <-
           {:consumed_items_count, Enum.count(consumed_items) == Enum.count(consumed_items_ids)},
         {:consumed_items_valid, {true, new_template}} <-
           {:consumed_items_valid, meets_fuse_requirements?(consumed_items)},
         {:can_afford, true} <-
           {:can_afford, Currencies.can_afford(user_id, new_template.upgrade_costs)} do
      result =
        Multi.new()
        |> Multi.run(:item, fn _, _ -> Items.insert_item(%{user_id: user_id, template_id: new_template.id}) end)
        |> Multi.run(:deleted_items, fn _, _ -> delete_consumed_items(consumed_items_ids) end)
        |> Multi.run(:currency_deduction, fn _, _ ->
          Currencies.substract_currencies(user_id, new_template.upgrade_costs)
        end)
        |> Transaction.run()

      case result do
        {:error, _, _, _} ->
          {:error, :transaction}

        {:ok, %{item: item}} ->
          Items.get_item(item.id)
      end
    else
      {:consumed_items_owned, false} ->
        {:error, :consumed_items_not_found}

      {:consumed_items_count, false} ->
        {:error, :consumed_items_not_found}

      {:consumed_items_valid, {false, _}} ->
        {:error, :consumed_items_invalid}

      {:can_afford, false} ->
        {:error, :cant_afford}
    end
  end

  defp delete_consumed_items(item_ids) do
    {amount_deleted, _return} = Items.delete_items(item_ids)

    if Enum.count(item_ids) == amount_deleted, do: {:ok, amount_deleted}, else: {:error, "failed"}
  end

  defp meets_fuse_requirements?([consumed_items_head | _] = consumed_items) do
    resulting_item_template = consumed_items_head.template.upgrades_into

    case resulting_item_template do
      nil ->
        {false, nil}

      _ ->
        # Check if all items fuse into the same one
        # and if the quantity of consumed items is the same as the required quantity to upgrade
        meets_requirements? =
          Enum.all?(consumed_items, fn item ->
            item.template.upgrades_into.config_id == resulting_item_template.config_id
          end) and
            resulting_item_template.upgrades_from_quantity == Enum.count(consumed_items)

        {meets_requirements?, resulting_item_template}
    end
  end
end

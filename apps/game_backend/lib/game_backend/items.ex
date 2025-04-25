defmodule GameBackend.Items do
  @moduledoc """
  The Items application defines utilites for interacting with Items, that are common across all games. Also defines the data structures themselves. Operations that can be done to an Item are:
  - Create
  - Equip to a unit
  - Fuse many into a new one with a better ItemTemplate

  Items are created by instantiating copies of ItemTemplates. This way, many users can have their own copy of the "Epic Sword" item. Likewise, this allows for a user to have many copies of it, each equipped to a different unit.
  """

  alias GameBackend.Ledger
  alias Ecto.Multi
  alias GameBackend.Items.Item
  alias GameBackend.Items.ItemTemplate
  alias GameBackend.Items.ConsumableItem
  alias GameBackend.Repo
  alias GameBackend.Units

  import Ecto.Query

  @doc """
  Equips an item to a unit. Returns an `{:ok, %Item{}}` tuple with the item's updated state.

  Returns `{:error, :item_not_found}` if the item_id doesn't exist.
  Returns `{:error, :item_not_owned}` if the item_id isn't owned by the user.
  Returns `{:error, :unit_not_owned}` if the unit we're equipping to isn't owned by the user.

  ## Examples

      iex> equip_item(user_id, item_id, unit_id)
      {:ok, %Item{unit_id: unit_id}}

      iex> equip_item(user_id, wrong_item_id, unit_id)
      {:error, :item_not_found}
  """
  def equip_item(user_id, item_id, unit_id) do
    with {_, {:ok, item}} <- {:get_item, get_item(item_id)},
         {_, true} <- {:item_owned, item.user_id == user_id},
         {_, true} <- {:unit_owned, Units.unit_belongs_to_user(unit_id, user_id)} do
      Item.equip_changeset(item, unit_id) |> Repo.update()
    else
      {:get_item, {:error, :not_found}} -> {:error, :item_not_found}
      {:item_owned, false} -> {:error, :item_not_owned}
      {:unit_owned, false} -> {:error, :unit_not_owned}
    end
  end

  @doc """
  Unequips an item from its unit. Returns an `{:ok, %Item{}}` tuple with the item's updated state.

  Returns `{:error, :item_not_found}` if the item_id doesn't exist.
  Returns `{:error, :item_not_owned}` if the item_id isn't owned by the user.

  ## Examples

      iex> unequip_item(user_id, item_id)
      {:ok, %Item{unit_id: nil}}

      iex> unequip_item(user_id, wrong_item_id)
      {:error, :item_not_found}
  """
  def unequip_item(user_id, item_id) do
    with {:ok, item} <- get_item(item_id),
         true <- item.user_id == user_id do
      Item.equip_changeset(item, nil) |> Repo.update()
    else
      {:error, :not_found} -> {:error, :item_not_found}
      false -> {:error, :item_not_owned}
    end
  end

  @doc """
  Inserts an item template.

  ## Examples

      iex> insert_item_template(%{field: value})
      {:ok, %ItemTemplate{}}

      iex> insert_item_template(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def insert_item_template(attrs) do
    %ItemTemplate{}
    |> ItemTemplate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get all item templates.

  ## Examples
      iex> get_item_templates()
      [%ItemTemplate{}]
  """
  def get_item_templates(), do: Repo.all(ItemTemplate)

  @doc """
  Get an item template by id.

  ## Examples

      iex> get_item_template(item_template_id)
      {:ok, %Item{}}

      iex> get_item_template(wrong_id)
      {:error, :not_found}
  """
  def get_item_template(item_template_id), do: Repo.get(ItemTemplate, item_template_id)

  @doc """
  Insert an ItemTemplate. If another one with the same config_id already exists, it updates it instead.
  """
  def upsert_item_template(attrs) do
    case get_item_template_by_config_id(attrs.config_id) do
      nil -> insert_item_template(attrs)
      item_template -> update_item_template(item_template, attrs)
    end
  end

  defp get_item_template_by_config_id(config_id) do
    Repo.get_by(ItemTemplate, config_id: config_id)
  end

  @doc """
  Update an ItemTemplate.
  """
  def update_item_template(item_template, attrs), do: item_template |> ItemTemplate.changeset(attrs) |> Repo.update()

  @doc """
  Inserts all ItemTemplates into the database.
  If another one already exists with the same config_id, it updates it instead.
  """
  def upsert_item_templates(attrs_list) do
    Enum.reduce(attrs_list, Multi.new(), fn attrs, multi ->
      # Cannot use Multi.insert because of the embeds_many
      Multi.run(multi, attrs.name, fn _, _ ->
        upsert_item_template(attrs)
      end)
    end)
    |> Repo.transaction()
  end

  @doc """
  Inserts an item.

  ## Examples

      iex> insert_item(%{field: value})
      {:ok, %Item{}}

      iex> insert_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def insert_item(attrs) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Get an item by id.

  ## Examples

      iex> get_item(item_id)
      {:ok, %Item{}}

      iex> get_item(wrong_id)
      {:error, :not_found}
  """
  def get_item(item_id) do
    case Repo.get(Item, item_id) |> Repo.preload([:template]) do
      nil -> {:error, :not_found}
      item -> {:ok, item}
    end
  end

  @doc """
  Get all items for a user.

  ## Examples

      iex> get_items(user_id)
      [%Item{}]
  """
  def get_items(user_id) do
    Repo.get_by(Item, user_id: user_id) |> Repo.preload([:template])
  end

  @doc """
  Gets all items from ids in a list.
  """
  def get_items_by_ids(item_ids) when is_list(item_ids),
    do: Repo.all(from(i in Item, where: i.id in ^item_ids, preload: [template: :upgrades_into]))

  @doc """
  Deletes all items in a list by ids.
  """
  def delete_items(item_ids), do: Repo.delete_all(from(u in Item, where: u.id in ^item_ids))

  @doc """
  Receives an item template name and a game id.
  Returns {:ok, item_template} if found or {:error, :not_found} otherwise.
  """
  def get_template_by_name_and_game_id(name, game_id) do
    case Repo.one(
           from(it in ItemTemplate,
             where: it.name == ^name and it.game_id == ^game_id
           )
         ) do
      nil -> {:error, :not_found}
      item_template -> {:ok, item_template}
    end
  end

  @doc """
  Get a user's item associated to the given item name.
  Fails if there are more than one item of the same name. Returns nil if there are none.
  """
  def get_item_by_name(item_name, user_id) do
    case Repo.one(
           from(item in Item,
             join: t in assoc(item, :template),
             where: t.name == ^item_name and item.user_id == ^user_id
           )
         ) do
      nil -> {:error, :not_found}
      item -> {:ok, item}
    end
  end

  @doc """
  Returns {:ok, :character_can_equip} if the item is for the unit's character.
  If not, returns {:error, :character_cannot_equip}
  """
  def character_can_equip(unit, item) do
    unit = Repo.preload(unit, :character)
    item = Repo.preload(item, :template)

    if unit.character.name in item.template.characters do
      {:ok, :character_can_equip}
    else
      {:error, :character_cannot_equip}
    end
  end

  @doc """
  Gets Item Template's purchase cost by given currency and item_template.
  Returns {:ok, purchase_cost} if found one.
  Returns {:error, :not_found} if there are none.
  """
  def get_item_template_purchase_cost_by_currency(item_template, currency_id) do
    purchase_cost =
      Map.get(item_template, :purchase_costs, [])
      |> Enum.find(fn purchase_cost -> purchase_cost.currency_id == currency_id end)

    case purchase_cost do
      nil -> {:error, :not_found}
      purchase_cost -> {:ok, purchase_cost}
    end
  end

  @doc """
  Receives a user_id, an item_template_id and a list of CurrencyCosts.
  Inserts new Item from given ItemTemplate for given User.
  Substract the amount of Currency to User by given params.
  Returns {:ok, map_of_ran_operations} in case of success.
  Returns {:error, failed_operation, failed_value, changes_so_far} if one of the operations fail.
  """
  def buy_item(user_id, template_id, purchase_costs_list) do
    Multi.new()
    |> Multi.run(:item, fn _, _ -> insert_item(%{user_id: user_id, template_id: template_id}) end)
    |> Ledger.register_currencies_spent(user_id, purchase_costs_list, "Item Bought") 
    |> Repo.transaction()
  end

  @doc """
  Returns the list of consumable_items.

  ## Examples

      iex> list_consumable_items()
      [%ConsumableItem{}, ...]

  """
  def list_consumable_items_by_version(version_id) do
    Repo.all(from(ci in ConsumableItem, where: ci.version_id == ^version_id))
  end

  @doc """
  Gets a single consumable_item.

  Raises `Ecto.NoResultsError` if the Consumable item does not exist.

  ## Examples

      iex> get_consumable_item!(123)
      %ConsumableItem{}

      iex> get_consumable_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_consumable_item!(id) do
    q =
      from(ci in ConsumableItem,
        where: ci.id == ^id,
        preload: [[mechanics: :parent_mechanic]]
      )

    Repo.one!(q)
  end

  @doc """
  Creates a consumable_item.

  ## Examples

      iex> create_consumable_item(%{field: value})
      {:ok, %ConsumableItem{}}

      iex> create_consumable_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_consumable_item(attrs \\ %{}) do
    %ConsumableItem{}
    |> ConsumableItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a consumable_item.

  ## Examples

      iex> update_consumable_item(consumable_item, %{field: new_value})
      {:ok, %ConsumableItem{}}

      iex> update_consumable_item(consumable_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_consumable_item(%ConsumableItem{} = consumable_item, attrs) do
    consumable_item
    |> ConsumableItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a consumable_item.

  ## Examples

      iex> delete_consumable_item(consumable_item)
      {:ok, %ConsumableItem{}}

      iex> delete_consumable_item(consumable_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_consumable_item(%ConsumableItem{} = consumable_item) do
    Repo.delete(consumable_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking consumable_item changes.

  ## Examples

      iex> change_consumable_item(consumable_item)
      %Ecto.Changeset{data: %ConsumableItem{}}

  """
  def change_consumable_item(%ConsumableItem{} = consumable_item, attrs \\ %{}) do
    ConsumableItem.changeset(consumable_item, attrs)
  end
end

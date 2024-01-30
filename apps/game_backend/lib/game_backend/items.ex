defmodule GameBackend.Items do
  @moduledoc """
  The Items application defines utilites for interacting with Items, that are common across all games. Also defines the data structures themselves. Operations that can be done to an Item are:
  - Create
  - Equip to a unit
  - Level up

  Items are created by instantiating copies of ItemTemplates. This way, many users can have their own copy of the "Epic Sword" item. Likewise, this allows for a user to have many copies of it, each with their own level and equipped to a different unit.
  """

  alias GameBackend.Items.Item
  alias GameBackend.Items.ItemTemplate
  alias GameBackend.Repo

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
    case Repo.get(Item, item_id) |> Repo.preload(:template) do
      nil -> {:error, :not_found}
      item -> {:ok, item}
    end
  end

  @doc """
  Increment an item's level by 1.

  ## Examples

      iex> level_up(%Item{level: 41})
      {:ok, %Item{level: 42}}
  """
  def level_up(item) do
    item
    |> Item.level_up_changeset()
    |> Repo.update()
  end
end

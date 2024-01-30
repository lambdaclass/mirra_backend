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

  def equip_item(user_id, item_id, unit_id) do
    case get_item(item_id) do
      nil ->
        {:error, :not_found}

      item ->
        if item.user_id == user_id,
          do: Item.equip_changeset(item, unit_id) |> Repo.update(),
          else: {:error, :not_found}
    end
  end

  def unequip_item(user_id, item_id) do
    case get_item(item_id) do
      nil ->
        {:error, :not_found}

      item ->
        if item.user_id == user_id,
          do: Item.equip_changeset(item, nil) |> Repo.update(),
          else: {:error, :not_found}
    end
  end

  def insert_item_template(attrs) do
    %ItemTemplate{}
    |> ItemTemplate.changeset(attrs)
    |> Repo.insert()
  end

  def get_item_templates(), do: Repo.all(ItemTemplate)

  def get_item_template(item_template_id), do: Repo.get(ItemTemplate, item_template_id)

  def insert_item(attrs) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  def get_item(item_id), do: Repo.get(Item, item_id)

  def level_up(item) do
    item
    |> Item.level_up_changeset()
    |> Repo.update()
  end
end

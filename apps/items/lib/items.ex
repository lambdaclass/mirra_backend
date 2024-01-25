defmodule Items do
  @moduledoc """
  Documentation for `Items`.
  """
  alias Items.Item
  alias Items.ItemTemplate
  alias Items.Repo

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

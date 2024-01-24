defmodule Items do
  @moduledoc """
  Documentation for `Items`.
  """
  alias Items.Item
  alias Items.ItemTemplate
  alias Items.Repo

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

  def level_up(item_id) do
    get_item(item_id)
    |> Item.level_up_changeset()
    |> Repo.update()
  end
end

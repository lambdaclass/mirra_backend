defmodule ChampionsOfMirra.Items do
  def get_item(item_id) do
    case Items.get_item(item_id) do
      nil -> {:error, :none_found}
      item -> {:ok, item}
    end
  end

  def level_up(item_id) do
    case Items.level_up(item_id) do
      {:ok, _item} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end

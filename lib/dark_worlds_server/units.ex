defmodule DarkWorldsServer.Units do
  alias DarkWorldsServer.Repo
  alias DarkWorldsServer.Units.Unit
  alias Ecto.Multi
  import Ecto.Query

  #########
  # Units #
  #########

  def insert_unit(attrs) do
    %Unit{}
    |> Unit.changeset(attrs)
    |> Repo.insert()
  end

  def update_unit_character(unit_id, character_id),
    do: Repo.update_all(from(u in Unit, where: u.id == ^unit_id, update: [set: [character_id: ^character_id]]), [])

  def get_unit(id), do: Repo.get(Unit, id) |> Repo.preload([:character, :user])

  def get_units(), do: Repo.all(Unit) |> Repo.preload([:character, :user])

  def get_units(user_id), do: Repo.all(user_units_query(user_id)) |> Repo.preload([:character])

  def get_selected_units(user_id),
    do: from(unit in user_units_query(user_id), where: unit.selected) |> Repo.all() |> Repo.preload([:character, :user])

  def delete_unit(id), do: Repo.get(Unit, id) |> Repo.delete()

  def unit_belongs_to_user(unit_id, user_id), do: user_unit_query(unit_id, user_id) |> Repo.exists?()

  def add_user_selected_unit(unit_id, user_id) do
    case user_unit_query(unit_id, user_id) |> Repo.one() do
      nil ->
        {:error, :unit_not_found}

      unit ->
        unit
        |> Unit.changeset(%{selected: true})
        |> Repo.update()
    end
  end

  def replace_user_selected_unit(unit_id, user_id) do
    user_id
    |> user_units_query()
    |> Repo.update_all(set: [selected: false])

    add_user_selected_unit(unit_id, user_id)
  end

  def remove_user_selected_unit(unit_id, user_id) do
    Repo.update_all(user_unit_query(unit_id, user_id), set: [selected: false])
  end

  defp user_units_query(user_id), do: from(unit in Unit, where: unit.user_id == ^user_id)

  defp user_unit_query(unit_id, user_id),
    do: from(unit in Unit, where: unit.id == ^unit_id and unit.user_id == ^user_id)
end

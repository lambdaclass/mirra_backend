defmodule DarkWorldsServer.Units do
  alias DarkWorldsServer.Repo
  alias DarkWorldsServer.Units.Unit
  alias DarkWorldsServer.Units.UserUnit
  alias Ecto.Multi
  import Ecto.Query

  #########
  # Units #
  #########

  def insert_unit(%{user_id: user_id} = attrs) do
    Multi.new()
    |> Multi.insert(:unit, Unit.changeset(%Unit{}, attrs))
    |> Multi.run(:user_unit, fn _repo, %{unit: unit} -> insert_user_unit(%{unit_id: unit.id, user_id: user_id}) end)
    |> Repo.transaction()
  end

  def insert_unit(_attrs), do: {:error, :no_user_id}

  def update_unit_character(unit_id, character_id),
    do: Repo.update_all(from(u in Unit, where: u.id == ^unit_id, update: [set: [character_id: ^character_id]]), [])

  def get_unit(id), do: Repo.get(Unit, id) |> Repo.preload([:character, :user])

  def get_units(), do: Repo.all(Unit) |> Repo.preload([:character, :user])

  def get_units(user_id), do: Repo.all(user_units_query(user_id)) |> Repo.preload([:character])

  def get_selected_units(user_id),
    do: Repo.all(from(unit in user_units_query(user_id), where: unit.selected)) |> Repo.preload([:character, :user])

  def delete_unit(id), do: Repo.get(Unit, id) |> Repo.delete()

  def insert_user_unit(attrs), do: %UserUnit{} |> UserUnit.changeset(attrs) |> Repo.insert()

  def unit_belongs_to_user(unit_id, user_id), do: Repo.exists?(user_unit_query(unit_id, user_id))

  def add_user_selected_unit(unit_id, user_id) do
    Repo.one(user_unit_query(unit_id, user_id))
    |> Unit.changeset(%{selected: true})
    |> Repo.update()
  end

  def replace_user_selected_unit(unit_id, user_id) do
    Repo.update_all(user_units_query(user_id), set: [selected: false])
    add_user_selected_unit(unit_id, user_id)
  end

  def remove_user_selected_unit(unit_id, user_id) do
    Repo.update_all(user_unit_query(unit_id, user_id), set: [selected: false])
  end

  defp user_unit_query(unit_id, user_id),
    do:
      from(unit in Unit,
        join: user_unit in UserUnit,
        on: unit.id == user_unit.unit_id,
        where: user_unit.unit_id == ^unit_id and user_unit.user_id == ^user_id
      )

  defp user_units_query(user_id),
    do:
      from(unit in Unit,
        join: user_unit in UserUnit,
        on: unit.id == user_unit.unit_id,
        where: user_unit.user_id == ^user_id
      )
end

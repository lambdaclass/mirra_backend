defmodule DarkWorldsServer.Units do
  alias DarkWorldsServer.Repo
  alias DarkWorldsServer.Units.Unit
  alias DarkWorldsServer.Units.UserUnit
  import Ecto.Query

  #########
  # Units #
  #########

  def insert_unit(%{user_id: user_id} = attrs) do
    case %Unit{}
         |> Unit.changeset(attrs)
         |> Repo.insert() do
      {:ok, unit} ->
        insert_user_unit(%{unit_id: unit.id, user_id: user_id})

      {:error, reason} ->
        {:error, reason}
    end
  end

  def insert_unit(_attrs), do: {:error, :no_user_id}

  def get_unit(id), do: Repo.get(Unit, id)

  def get_units(), do: Repo.all(Unit)

  def get_units(user_id), do: Repo.all(user_units_query(user_id))

  def get_selected_units(user_id),
    do:
      Repo.all(
        from(unit in Unit,
          join: user_unit in UserUnit,
          on: unit.id == user_unit.id,
          where: user_unit.user_id == ^user_id and user_unit.selected
        )
      )

  def insert_user_unit(attrs), do: %UserUnit{} |> UserUnit.changeset(attrs) |> Repo.insert()

  def unit_belongs_to_user(unit_id, user_id), do: Repo.exists?(user_unit_query(unit_id, user_id))

  def add_user_selected_unit(unit_id, user_id) do
    Repo.one(user_unit_query(unit_id, user_id))
    |> UserUnit.changeset(%{selected: true})
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
        on: unit.id == user_unit.id,
        where: user_unit.unit_id == ^unit_id and user_unit.user_id == ^user_id
      )

  defp user_units_query(user_id),
    do: from(unit in Unit, join: user_unit in UserUnit, on: unit.id == user_unit.id, where: user_unit.id == ^user_id)
end

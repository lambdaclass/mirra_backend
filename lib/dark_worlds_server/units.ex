defmodule DarkWorldsServer.Units do
  @moduledoc """
  Operations with Units.
  """

  alias DarkWorldsServer.Config.Characters
  alias DarkWorldsServer.Config.Characters.Character
  alias DarkWorldsServer.Repo
  alias DarkWorldsServer.Units.Unit
  alias Ecto.Multi
  import Ecto.Query

  #########
  # Units #
  #########

  @doc """
  Inserts a unit.
  """
  def insert_unit(attrs) do
    %Unit{}
    |> Unit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Sets the selected value of a unit.
  """
  def update_unit(unit, params) do
    unit
    |> Unit.edit_changeset(params)
    |> Repo.update()
  end

  @doc """
  Changes a unit's character. Only really makes sense to call this during our config import process.
  """
  def update_unit_character(unit, character_id),
    do: unit |> Unit.character_changeset(%{character_id: character_id}) |> Repo.update()

  @doc """
  Gets a unit given its id.
  """
  def get_unit(id), do: Repo.get(Unit, id) |> Repo.preload([:character, :user])

  @doc """
  Gets all units from all users.
  """
  def get_units(), do: Repo.all(Unit) |> Repo.preload([:character, :user])

  @doc """
  Gets all units for a user.
  """
  def get_units(user_id), do: Repo.all(user_units_query(user_id)) |> Repo.preload([:character])

  @doc """
  Gets the user's selected unit. Takes the highest leveled one if there's many. Returns nil if there are none.
  """
  def get_selected_unit(user_id),
    do:
      from(unit in user_units_query(user_id), where: unit.selected, order_by: [desc: :level], limit: 1)
      |> Repo.one()
      |> Repo.preload([:character, :user])

  @doc """
  Gets the user's single selected unit. Fails if they have many or none.
  """
  def get_selected_unit!(user_id),
    do:
      from(unit in user_units_query(user_id), where: unit.selected) |> Repo.one!() |> Repo.preload([:character, :user])

  @doc """
  Get all of a user's selected units.
  """
  def get_selected_units(user_id),
    do: from(unit in user_units_query(user_id), where: unit.selected) |> Repo.all() |> Repo.preload([:character, :user])

  @doc """
  Get a user's unit associated to the given character.
  Fails if there are more than one unit of the same character. Returns nil if there are none.
  """
  def get_unit_by_character_name(character_name, user_id),
    do:
      Repo.one(
        from(unit in user_units_query(user_id),
          join: character in Character,
          on: unit.character_id == character.id,
          where: character.name == ^character_name
        )
      )

  @doc """
  Deletes a unit.
  """
  def delete_unit(%Unit{} = unit), do: Repo.delete(unit)
  def delete_unit(id), do: Repo.get(Unit, id) |> delete_unit()

  @doc """
  Wrapper for replace_selected_unit/2 when unit is identifiable by character name.
  If no unit with said character is found, it will be created.
  """
  def replace_selected_character(character_name, user_id, creation_params) do
    case(get_unit_by_character_name(character_name, user_id)) do
      nil ->
        Multi.new()
        |> Multi.run(:remove_all_selected, fn _repo, _changes ->
          {_amount, nil} = remove_all_selected_units(user_id)
          {:ok, nil}
        end)
        |> Multi.run(
          :insert_unit,
          fn _repo, _changes ->
            insert_unit(%{
              user_id: user_id,
              character_id: Characters.get_character_by_name(character_name).id,
              selected: true,
              level: Map.get(creation_params, :level, 1),
              position: Map.get(creation_params, :position, nil)
            })
          end
        )
        |> Repo.transaction()

      unit ->
        replace_selected_unit(unit.id, user_id)
    end
  end

  @doc """
  Wrapper for replace_selected_unit/2 when unit is identifiable by character name.
  If no unit with said character is found, it will return nil
  """
  def replace_selected_character(character_name, user_id) do
    case get_unit_by_character_name(character_name, user_id) do
      nil -> nil
      unit -> replace_selected_unit(unit.id, user_id)
    end
  end

  @doc """
  Sets a unit as selected and unselects all others for a user.
  """
  def replace_selected_unit(unit_id, user_id) do
    # We work with unit_id here because the remove selected function could affect the unit, making it outdated.
    Multi.new()
    |> Multi.run(:remove_all_selected, fn _repo, _changes ->
      {_amount, nil} = remove_all_selected_units(user_id)
      {:ok, nil}
    end)
    |> Multi.run(:set_selected, fn _repo, _changes ->
      unit_id
      |> get_unit()
      |> update_unit(%{selected: true})
    end)
    |> Repo.transaction()
  end

  @doc """
  Sets all of the user's units' selected value to false.
  """
  def remove_all_selected_units(user_id),
    do:
      user_id
      |> user_units_query()
      |> Repo.update_all(set: [selected: false])

  defp user_units_query(user_id), do: from(unit in Unit, where: unit.user_id == ^user_id)
end

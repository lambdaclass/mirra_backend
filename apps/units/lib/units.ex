defmodule Units do
  @moduledoc """
  Operations with Units.
  """

  import Ecto.Query

  alias Units.Repo
  alias Units.Unit
  alias Units.Characters.Character

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
      from(unit in user_units_query(user_id),
        where: unit.selected,
        order_by: [desc: :level],
        limit: 1
      )
      |> Repo.one()
      |> Repo.preload([:character, :user])

  @doc """
  Gets the user's single selected unit. Fails if they have many or none.
  """
  def get_selected_unit!(user_id),
    do:
      from(unit in user_units_query(user_id), where: unit.selected)
      |> Repo.one!()
      |> Repo.preload([:character, :user])

  @doc """
  Get all of a user's selected units.
  """
  def get_selected_units(user_id),
    do:
      from(unit in user_units_query(user_id), where: unit.selected)
      |> Repo.all()
      |> Repo.preload([:character, :user])

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
  Sets all of the user's units' selected value to false.
  """
  def remove_all_selected_units(user_id),
    do:
      user_id
      |> user_units_query()
      |> Repo.update_all(set: [selected: false])

  defp user_units_query(user_id), do: from(unit in Unit, where: unit.user_id == ^user_id)

  @doc """
  Get all existing characters.
  """
  def all_characters(), do: Repo.all(Character)

  @doc """
  Get all existing characters from given factions.
  """
  def all_characters_from_factions(possible_factions), do:
    Units.Repo.all(from(q in Character, where: q.faction in ^possible_factions))

  # No insertion to the DB, we use this for levels only
  def create_unit_for_level(possible_characters, level) do
    character = Enum.random(possible_characters)

    %Unit{level: level, tier: 1, selected: true, character_id: character.id}
  end

end

defmodule GameBackend.Units do
  @moduledoc """
  The Units module defines utilites for interacting with Units, that are common across all games. Also defines the data structures themselves. Operations that can be done to a Unit are:
  - Create
  - Select to a slot/Unselect

  Units are created by instantiating copies of Characters. This way, many users can have their own copy of the "Muflus" character. Likewise, this allows for a user to have many copies of them, each with their own level, selected status and slot.
  """

  import Ecto.Query

  alias GameBackend.Repo
  alias GameBackend.Units
  alias GameBackend.Units.Unit
  alias GameBackend.Units.Characters.Character

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
  def update_selected(unit, params) do
    unit
    |> Unit.selected_changeset(params)
    |> Repo.update()
  end

  def select_unit(user_id, unit_id, slot \\ nil) do
    unit = Units.get_unit(unit_id) || %{}

    if Map.get(unit, :user_id, nil) == user_id do
      case update_selected(unit, %{selected: true, slot: slot}) do
        {:ok, unit} -> unit
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :not_found}
    end
  end

  def unselect_unit(user_id, unit_id) do
    unit = Units.get_unit(unit_id) || %{}

    if Map.get(unit, :user_id, nil) == user_id do
      case update_selected(unit, %{selected: false, slot: nil}) do
        {:ok, unit} -> unit
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, :not_found}
    end
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
  def all_characters_from_factions(possible_factions),
    do: Repo.all(from(q in Character, where: q.faction in ^possible_factions))

  @doc """
  Create params for a level with a random character.
  """
  def unit_params_for_level(possible_characters, unit_level) do
    character = Enum.random(possible_characters)

    %{unit_level: unit_level, tier: 1, selected: true, character_id: character.id}
  end

  def unit_belongs_to_user(unit_id, user_id),
    do: Map.get(get_unit(unit_id) || %{}, :user_id) == user_id
end

defmodule GameBackend.Units do
  @moduledoc """
  The Units module defines utilites for interacting with Units, that are common across all games. Also defines the data structures themselves. Operations that can be done to a Unit are:
  - Create
  - Select to a slot/Unselect
  - Level up
  - Tier up

  Units are created by instantiating copies of Characters. This way, many users can have their own copy of the "Muflus" character.
  Likewise, this allows for a user to have many copies of them, each with their own level, selected status and slot.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias GameBackend.Configuration
  alias GameBackend.Repo
  alias GameBackend.Transaction
  alias GameBackend.Units.Unit
  alias GameBackend.Units.Characters.Character
  alias GameBackend.Units.UnitSkin
  alias GameBackend.Users.Currencies

  @doc """
  Inserts a unit.
  """
  def insert_unit(attrs) do
    %Unit{}
    |> Unit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a unit.
  """
  def update_unit(unit, params) do
    unit
    |> Unit.update_changeset(params)
    |> Repo.update()
  end

  @doc """
  Sets a unit as selected in the given slot.
  """
  def select_unit(user_id, unit_id, slot \\ nil) do
    with {:unit, {:ok, unit}} <- {:unit, get_unit(unit_id)},
         {:unit_owned, true} <- {:unit_owned, unit.user_id == user_id} do
      update_unit(unit, %{selected: true, slot: slot})
    else
      {:unit, {:error, :not_found}} -> {:error, :not_found}
      {:unit_owned, false} -> {:error, :not_owned}
    end
  end

  @doc """
  Sets a unit as unselected and clears its slot.
  """
  def unselect_unit(user_id, unit_id) do
    with {:unit, {:ok, unit}} <- {:unit, get_unit(unit_id)},
         {:unit_owned, true} <- {:unit_owned, unit.user_id == user_id} do
      update_unit(unit, %{selected: false, slot: nil})
    else
      {:unit, {:error, :not_found}} -> {:error, :not_found}
      {:unit_owned, false} -> {:error, :not_owned}
    end
  end

  @doc """
  Gets a unit given its id.
  """
  def get_unit(id) do
    unit =
      Repo.get(Unit, id)
      |> Repo.preload([
        :user,
        :items,
        character: [[basic_skill: [mechanics: :apply_effects_to], ultimate_skill: [mechanics: :apply_effects_to]]]
      ])

    if unit, do: {:ok, unit}, else: {:error, :not_found}
  end

  @doc """
  Gets all units from all users.
  """
  def get_units(), do: Repo.all(Unit) |> Repo.preload([:character, :user, :items])

  @doc """
  Gets all units from ids in a list.
  """
  def get_units_by_ids(unit_ids) when is_list(unit_ids),
    do: Repo.all(from(u in Unit, where: u.id in ^unit_ids, preload: [:character, :user, :items]))

  @doc """
  Gets all units for a user.
  """
  def get_units(user_id),
    do: Repo.all(user_units_query(user_id)) |> Repo.preload([:character, :user, :items])

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
      |> Repo.preload([:character, :user, [skins: :skin]])

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
      |> Repo.preload([
        :user,
        items: :template,
        character: [basic_skill: [mechanics: :apply_effects_to], ultimate_skill: [mechanics: :apply_effects_to]]
      ])

  @doc """
  Get a user's unit associated to the given character.
  Fails if there are more than one unit of the same character. Returns nil if there are none.
  """
  def get_unit_by_character_name(character_name, user_id) do
    character_name = String.downcase(character_name)

    case Repo.one(
           from(unit in user_units_query(user_id),
             join: character in Character,
             on: unit.character_id == character.id,
             where: character.name == ^character_name,
             preload: [skins: :skin]
           )
         ) do
      nil -> {:error, :not_found}
      unit -> {:ok, unit}
    end
  end

  def get_unit_by_character_id(user_id, character_id) do
    case Repo.one(
           from(unit in user_units_query(user_id),
             join: character in Character,
             on: unit.character_id == character.id,
             where: character.id == ^character_id
           )
         ) do
      nil -> {:error, :not_found}
      unit -> {:ok, unit}
    end
  end

  @doc """
  Deletes a unit.
  """
  def delete_unit(%Unit{} = unit), do: Repo.delete(unit)
  def delete_unit(id), do: Repo.get(Unit, id) |> delete_unit()

  @doc """
  Deletes all units in a list by ids.
  """
  def delete_units(unit_ids), do: Repo.delete_all(from(u in Unit, where: u.id in ^unit_ids))

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
  def unit_params_for_level(possible_characters, level, slot) do
    character = Enum.random(possible_characters)

    %{level: level, tier: 1, rank: 1, selected: true, character_id: character.id, slot: slot}
  end

  @doc """
  Returns whether a unit belongs to a user.
  """
  def unit_belongs_to_user(unit_id, user_id),
    do: Repo.exists?(from(u in Unit, where: u.id == ^unit_id and u.user_id == ^user_id))

  @doc """
  Increment a unit's level (not to be confused with units' `level` association).

  ## Examples

      iex> add_level(%Unit{level: 41}, 1)
      {:ok, %Unit{level: 42}}
  """
  def add_level(unit, level \\ 1) do
    unit
    |> Unit.update_changeset(%{level: unit.level + level})
    |> Repo.update()
  end

  @doc """
  Increment a unit's tier.

  ## Examples

      iex> add_tier(%Unit{tier: 41}, 1)
      {:ok, %Unit{tier: 42}}
  """
  def add_tier(unit, tier \\ 1) do
    unit
    |> Unit.update_changeset(%{tier: unit.tier + tier})
    |> Repo.update()
  end

  @doc """
  Increment a unit's rank.

  ## Examples

      iex> add_rank(%Unit{rank: 41}, 1)
      {:ok, %Unit{rank: 42}}
  """
  def add_rank(unit, rank \\ 1) do
    unit
    |> Unit.update_changeset(%{rank: unit.rank + rank})
    |> Repo.update()
  end

  def get_unit_default_values(char_params) do
    %{
      level: 1,
      prestige: 0,
      selected: false,
      character_id: char_params.id
    }
  end

  def list_units_by_user(user_id) do
    {:ok, Repo.all(from(u in Unit, where: u.user_id == ^user_id, preload: :character))}
  end

  def select_unit_character(units, character_name) do
    character_name = String.downcase(character_name)

    Enum.reduce(units, Multi.new(), fn unit, multi ->
      Multi.update(
        multi,
        "select_character_#{unit.id}",
        Unit.changeset(unit, %{selected: unit.character.name == character_name})
      )
    end)
    |> Repo.transaction()
  end

  def select_unit_skin(unit, skin_name) do
    Enum.reduce(unit.skins, Multi.new(), fn unit_skin, multi ->
      Multi.update(
        multi,
        "select_skin_#{unit_skin.id}",
        UnitSkin.changeset(unit_skin, %{selected: unit_skin.skin.name == skin_name})
      )
    end)
    |> Repo.transaction()
  end

  @doc """
  Returns a boolean value indicating if the unit has the skin or not.
  """
  def has_skin?(unit, skin_name) do
    unit = Repo.preload(unit, skins: :skin)
    Enum.any?(unit.skins, fn unit_skin -> unit_skin.skin.name == skin_name end)
  end

  @doc """
  Inserts a UnitSkin into the database.
  """
  def insert_unit_skin(attrs) do
    %UnitSkin{}
    |> UnitSkin.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Levels up a user's unit and substracts the currency cost from the user.

  Returns `{:error, :not_found}` if unit doesn't exist or if it's not owned by user.
  Returns `{:error, :cant_afford}` if user cannot afford the cost.
  Returns `{:ok, %{unit: %Unit{}, user_currency: %UserCurrency{}}}` if succesful.
  """
  def level_up(user_id, unit_id) do
    level_up_config = get_current_level_up_config()

    with {:ok, unit} <- get_unit(unit_id),
         {:ok, true} <- validate_unit_owned(unit.user_id, user_id),
         {:ok, true} <- validate_next_level_exists_in_config(level_up_config.level_info, unit.level),
         costs = calculate_level_up_cost(unit, level_up_config),
         {:can_afford, true} <- {:can_afford, Currencies.can_afford(user_id, costs)} do
      Multi.new()
      |> Multi.run(:unit, fn _, _ -> add_level(unit) end)
      |> Multi.run(:user_currency, fn _, _ ->
        Currencies.substract_currencies(user_id, costs)
      end)
      |> Transaction.run()
    end
  end

  defp validate_unit_owned(user_id, user_id) do
    {:ok, true}
  end

  defp validate_unit_owned(_unit_user_id, _user_id) do
    {:error, :not_found}
  end

  defp validate_next_level_exists_in_config(levels_info, current_level) do
    if Enum.any?(levels_info, fn level_info -> level_info.level == current_level + 1 end) do
      {:ok, true}
    else
      {:error, :no_more_levels}
    end
  end

  @doc """
  Calculate how much it costs for a unit to be leveled up.
  Returns a `%CurrencyCost{}` list.
  """
  def calculate_level_up_cost(unit, level_up_config) do
    next_level = unit.level + 1

    level_up_config.level_info
    |> Enum.filter(fn level_info -> level_info.level == next_level end)
    |> Enum.map(fn level_info ->
      level_info.currency_costs
    end)
    |> Enum.concat()
  end

  defp get_current_level_up_config() do
    version = Configuration.get_current_version()

    Configuration.get_level_up_configuration_by_version(version.id)
  end

  def get_level_up_settings() do
    get_current_level_up_config().level_info
    |> Enum.map(fn level ->
      currency_costs =
        level.currency_costs
        |> Enum.map(fn currency_cost ->
          %{
            amount: currency_cost.amount,
            currency_id: currency_cost.currency_id,
            currency: %{
              name: currency_cost.currency.name
            }
          }
        end)

      %{
        level: level.level,
        currency_costs: currency_costs,
        stat_increase_percentage: level.stat_increase_percentage
      }
    end)
    |> Enum.to_list()
  end
end

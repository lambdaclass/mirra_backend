defmodule Champions.Units do
  @moduledoc """
  Units logic for Champions Of Mirra.
  """

  alias GameBackend.Units

  @doc """
  Marks a unit as selected for a user. Units cannot be selected to the same slot.

  Returns :not_found if unit doesn't exist or if it's now owned by the user.
  Returns the unit's new state if succesful.
  """
  def select_unit(_user_id, _unit_id, nil), do: {:error, :no_slot}
  def select_unit(_user_id, _unit_id, slot) when slot > 4, do: {:error, :out_of_bounds}

  def select_unit(user_id, unit_id, slot) do
    if Units.get_selected_units(user_id) |> Enum.any?(&(&1.slot == slot)) do
      {:error, :slot_occupied}
    else
      Units.select_unit(user_id, unit_id, slot)
    end
  end

  def unselect_unit(user_id, unit_id) do
    Units.unselect_unit(user_id, unit_id)
  end

  @doc """
  Get a unit's max health stat for battle. Buffs from items and similar belong here.

  For now, we just return the base character's stat.
  """
  def get_max_health(unit) do
    unit.character.base_health
  end

  @doc """
  Get a unit's attack stat for battle. Buffs from items and similar belong here.

  For now, we just return the base character's stat.
  """
  def get_attack(unit) do
    unit.character.base_attack
  end

  @doc """
  Get a unit's armor stat for battle. Buffs from items and similar belong here.

  For now, we just return the base character's stat.
  """
  def get_armor(unit) do
    unit.character.base_armor
  end
end

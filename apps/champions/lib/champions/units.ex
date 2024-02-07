defmodule Champions.Units do
  @moduledoc """
  Units logic for Champions Of Mirra.

  Slots can range from 1 to 5 for selected units.
  """

  alias GameBackend.Units
  alias GameBackend.Users.Currencies

  @doc """
  Marks a unit as selected for a user. Units cannot be selected to the same slot.

  Returns :not_found if unit doesn't exist or if it's now owned by the user.
  Returns the unit's new state if succesful.
  """
  def select_unit(_user_id, _unit_id, nil), do: {:error, :no_slot}
  def select_unit(_user_id, _unit_id, slot) when slot not in 1..5, do: {:error, :out_of_bounds}

  def select_unit(user_id, unit_id, slot) do
    if Units.get_selected_units(user_id) |> Enum.any?(&(&1.slot == slot)) do
      {:error, :slot_occupied}
    else
      Units.select_unit(user_id, unit_id, slot)
    end
  end

  def unselect_unit(user_id, unit_id), do: Units.unselect_unit(user_id, unit_id)

  @doc """
  Level up a user's unit and substracts the currency cost from the user.

  Returns `{:error, :not_found}` if unit doesn't exist or if it's not owned by user.
  Returns `{:error, :cant_afford}` if user cannot afford the cost.
  Returns `{:ok, unit: %Unit{}, user_currency: %UserCurrency{}}` if succesful.
  """
  def level_up(user_id, unit_id) do
    with {:unit, {:ok, unit}} <- {:unit, Units.get_unit(unit_id)},
         {:unit_owned, true} <- {:unit_owned, unit.user_id == user_id},
         {currency, cost} = calculate_level_up_cost(unit),
         {:can_afford, true} <-
           {:can_afford, Currencies.can_afford(user_id, currency, cost)} do
      Units.level_up(unit, currency, cost)
    else
      {:unit, {:error, :not_found}} -> {:error, :not_found}
      {:unit_owned, false} -> {:error, :not_owned}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  defp calculate_level_up_cost(unit),
    do: {Currencies.get_currency_by_name!("Gold").id, unit.unit_level |> Math.pow(2) |> round()}
end

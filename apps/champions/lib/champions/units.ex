defmodule Champions.Units do
  @moduledoc """
  Units logic for Champions Of Mirra.

  - Slots can range from 1 to 5 for selected units.
  - Level ups cost an amount of gold that depends on the unit level.
  - Tier ups cost an amount of gold that depends on the unit level, plus a set number of gems.
  """

  alias Ecto.Multi
  alias GameBackend.Units
  alias GameBackend.Users.Currencies
  alias GameBackend.Users.Currencies.UserCurrency

  @star1 1
  @star2 2
  @star3 3
  @star4 4
  @star5 5
  @illumination1 6
  @illumination2 7
  @illumination3 8
  # @awakened 9

  @doc """
  Marks a unit as selected for a user. Units cannot be selected to the same slot.

  Returns `:not_found` if unit doesn't exist or if it's now owned by the user.
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

  @doc """
  Sets a unit as unselected for a user. Clears the `slot` field.

  Returns `:not_found` if unit doesn't exist or if it's now owned by the user.
  Returns the unit's new state if succesful.
  """
  def unselect_unit(user_id, unit_id), do: Units.unselect_unit(user_id, unit_id)

  @doc """
  Levels up a user's unit and substracts the currency cost from the user.

  Returns `{:error, :not_found}` if unit doesn't exist or if it's not owned by user.
  Returns `{:error, :cant_afford}` if user cannot afford the cost.
  Returns `{:error, :cant_level_up}`if unit cant level up due to tier restrictions.
  Returns `{:ok, unit: %Unit{}, user_currency: %UserCurrency{}}` if succesful.
  """
  def level_up(user_id, unit_id) do
    with {:unit, {:ok, unit}} <- {:unit, Units.get_unit(unit_id)},
         {:unit_owned, true} <- {:unit_owned, unit.user_id == user_id},
         {:can_level_up, true} <- {:can_level_up, can_level_up(unit)},
         costs = calculate_level_up_cost(unit),
         {:can_afford, true} <-
           {:can_afford, Currencies.can_afford(user_id, costs)} do
      result =
        Multi.new()
        |> Multi.run(:unit, fn _, _ -> Units.add_level(unit) end)
        |> Multi.run(:user_currency, fn _, _ ->
          add_user_currencies(unit, costs)
        end)
        |> GameBackend.Transaction.run()

      case result do
        {:error, reason} ->
          {:error, reason}

        {:ok, %{unit: unit, user_currency: user_currency}} ->
          {:ok,
           %{unit: unit, user_currency: Enum.map(user_currency, &UserCurrency.preload_currency/1)}}
      end
    else
      {:unit, {:error, :not_found}} -> {:error, :not_found}
      {:unit_owned, false} -> {:error, :not_found}
      {:can_level_up, false} -> {:error, :cant_level_up}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  defp add_user_currencies(unit, costs) do
    result =
      Enum.map(costs, fn {currency_id, cost} ->
        Currencies.add_currency(unit.user_id, currency_id, -cost)
      end)

    if Enum.all?(result, fn
         {:ok, _} -> true
         _ -> false
       end) do
      {:ok,
       Enum.map(result, fn {_ok, user_currency} -> UserCurrency.preload_currency(user_currency) end)}
    else
      {:error, "failed"}
    end
  end

  @doc """
  Returns whether a unit can level up. Level is blocked by tier.
  """
  def can_level_up(unit), do: can_level_up(unit.tier, unit.unit_level)
  defp can_level_up(1, level) when level < 20, do: true
  defp can_level_up(2, level) when level < 40, do: true
  defp can_level_up(3, level) when level < 60, do: true
  defp can_level_up(4, level) when level < 80, do: true
  defp can_level_up(5, level) when level < 100, do: true
  defp can_level_up(6, level) when level < 120, do: true
  defp can_level_up(7, level) when level < 140, do: true
  defp can_level_up(8, level) when level < 160, do: true
  defp can_level_up(9, level) when level < 180, do: true
  defp can_level_up(10, level) when level < 200, do: true
  defp can_level_up(11, level) when level < 220, do: true
  defp can_level_up(12, level) when level < 250, do: true
  defp can_level_up(_, _), do: false

  @doc """
  Calculate how much it costs for a unit to be leveled up.

  Returns a `{currency_id, amount}` tuple list.
  """
  def calculate_level_up_cost(unit),
    do: [{Currencies.get_currency_by_name!("Gold").id, unit.unit_level |> Math.pow(2) |> round()}]

  @doc """
  Tiers up a user's unit and substracts the currency cost from the user.

  Returns `{:error, :not_found}` if unit doesn't exist or if it's not owned by user.
  Returns `{:error, :cant_afford}` if user cannot afford the cost.
  Returns `{:ok, unit: %Unit{}, user_currency: %UserCurrency{}}` if succesful.
  """
  def tier_up(user_id, unit_id) do
    with {:unit, {:ok, unit}} <- {:unit, Units.get_unit(unit_id)},
         {:unit_owned, true} <- {:unit_owned, unit.user_id == user_id},
         {:can_tier_up, true} <- {:can_tier_up, can_tier_up(unit)},
         costs = calculate_tier_up_cost(unit),
         {:can_afford, true} <-
           {:can_afford, Currencies.can_afford(user_id, costs)} do
      result =
        Multi.new()
        |> Multi.run(:unit, fn _, _ -> Units.add_tier(unit) end)
        |> Multi.run(:user_currency, fn _, _ ->
          add_user_currencies(unit, costs)
        end)
        |> GameBackend.Transaction.run()

      case result do
        {:error, reason} ->
          {:error, reason}

        {:ok, %{unit: unit, user_currency: user_currency}} ->
          {:ok,
           %{unit: unit, user_currency: Enum.map(user_currency, &UserCurrency.preload_currency/1)}}
      end
    else
      {:unit, {:error, :not_found}} -> {:error, :not_found}
      {:unit_owned, false} -> {:error, :not_owned}
      {:can_tier_up, false} -> {:error, :cant_tier_up}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  @doc """
  Returns whether a unit can tier up. tier is blocked by tier.
  """
  def can_tier_up(unit), do: can_tier_up(unit.rank, unit.tier)
  defp can_tier_up(@star1, tier) when tier < 1, do: true
  defp can_tier_up(@star2, tier) when tier < 2, do: true
  defp can_tier_up(@star3, tier) when tier < 3, do: true
  defp can_tier_up(@star4, tier) when tier < 4, do: true
  defp can_tier_up(@star5, tier) when tier < 5, do: true
  defp can_tier_up(@illumination1, tier) when tier < 7, do: true
  defp can_tier_up(@illumination2, tier) when tier < 9, do: true
  defp can_tier_up(@illumination3, tier) when tier < 11, do: true
  defp can_tier_up(_, _), do: false

  @doc """
  Calculate how much it costs for a unit to be tiered up.

  Returns a `{currency_id, amount}` tuple list.
  """
  def calculate_tier_up_cost(unit),
    do: [
      {Currencies.get_currency_by_name!("Gold").id, unit.unit_level |> Math.pow(2) |> round()},
      {Currencies.get_currency_by_name!("Gems").id, 50}
    ]

  # def fuse(user_id, unit_id, consumed_units) do
  #   with {:unit, {:ok, unit}} <- {:unit, Units.get_unit(unit_id)},
  #   {:unit_owned, true} <- {:unit_owned, unit.user_id == user_id},
  #   {:can_level_up, true} <- {:can_level_up, can_level_up(unit)},
  #   level_up_cost = calculate_level_up_cost(unit),
  #   {:can_afford, true} <-
  #     {:can_afford, Currencies.can_afford(user_id, level_up_cost)} do
  #       Units.rank_up()
  #     else
  #       _ -> :err
  #     end
  # end
end

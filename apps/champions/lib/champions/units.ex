defmodule Champions.Units do
  @moduledoc """
  Units logic for Champions Of Mirra.

  - Slots can range from 1 to 5 for selected units.
  - Level ups cost an amount of gold that depends on the unit level.
  - Tier ups cost an amount of gold that depends on the unit level, plus a set number of gems.
  """

  alias Ecto.Multi
  alias GameBackend.Transaction
  alias GameBackend.Units
  alias GameBackend.Units.Characters.Character
  alias GameBackend.Units.Unit
  alias GameBackend.Users.Currencies
  alias GameBackend.Users.Currencies.CurrencyCost

  @star1 1
  @star2 2
  @star3 3
  @star4 4
  @star5 5
  @illumination1 6
  @illumination2 7
  @illumination3 8
  @awakened 9

  @epic 3
  @rare 2
  @common 1

  def get_rank(:star1), do: @star1
  def get_rank(:star2), do: @star2
  def get_rank(:star3), do: @star3
  def get_rank(:star4), do: @star4
  def get_rank(:star5), do: @star5
  def get_rank(:illumination1), do: @illumination1
  def get_rank(:illumination2), do: @illumination2
  def get_rank(:illumination3), do: @illumination3
  def get_rank(:awakened), do: @awakened

  def get_quality(:epic), do: @epic
  def get_quality(:rare), do: @rare
  def get_quality(:common), do: @common

  @doc """
  Marks a unit as selected for a user. Units cannot be selected to the same slot.

  Returns `:not_found` if unit doesn't exist or if it's now owned by the user.
  Returns the unit's new state if succesful.
  """
  def select_unit(_user_id, _unit_id, nil), do: {:error, :no_slot}
  def select_unit(_user_id, _unit_id, slot) when slot not in 1..6, do: {:error, :out_of_bounds}

  def select_unit(user_id, unit_id, slot) do
    if Units.get_selected_units(user_id) |> Enum.any?(&(&1.slot == slot)),
      do: {:error, :slot_occupied},
      else: Units.select_unit(user_id, unit_id, slot)
  end

  @doc """
  Sets a unit as unselected for a user. Clears the `slot` field.

  Returns `:not_found` if unit doesn't exist or if it's now owned by the user.
  Returns the unit's new state if succesful.
  """
  def unselect_unit(user_id, unit_id), do: Units.unselect_unit(user_id, unit_id)

  ############
  # Level Up #
  ############

  @doc """
  Levels up a user's unit and substracts the currency cost from the user.

  Returns `{:error, :not_found}` if unit doesn't exist or if it's not owned by user.
  Returns `{:error, :cant_afford}` if user cannot afford the cost.
  Returns `{:error, :cant_level_up}`if unit cant level up due to tier restrictions.
  Returns `{:ok, %{unit: %Unit{}, user_currency: %UserCurrency{}}}` if succesful.
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
          Currencies.substract_currencies(user_id, costs)
        end)
        |> Transaction.run()

      case result do
        {:error, reason} ->
          {:error, reason}

        {:error, _, _, _} ->
          {:error, :transaction}

        {:ok, %{unit: unit, user_currency: user_currency}} ->
          {:ok, %{unit: unit, user_currency: user_currency}}
      end
    else
      {:unit, {:error, :not_found}} -> {:error, :not_found}
      {:unit_owned, false} -> {:error, :not_found}
      {:can_level_up, false} -> {:error, :cant_level_up}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  @doc """
  Calculate how much it costs for a unit to be leveled up.
  Returns a `%CurrencyCost{}` list.
  """
  def calculate_level_up_cost(unit),
    do: [
      %CurrencyCost{
        currency_id: Currencies.get_currency_by_name!("Gold").id,
        amount: unit.level |> Math.pow(2) |> round()
      }
    ]

  @doc """
  Returns whether a unit can level up. Level is blocked by tier.

  This will eventually be provided by configuration files.
  """
  def can_level_up(unit), do: can_level_up(unit.tier, unit.level)
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

  ###########
  # Tier Up #
  ###########

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
          Currencies.substract_currencies(user_id, costs)
        end)
        |> GameBackend.Transaction.run()

      case result do
        {:error, reason} ->
          {:error, reason}

        {:error, _, _, _} ->
          {:error, :transaction}

        {:ok, %{unit: unit, user_currency: user_currency}} ->
          {:ok, %{unit: unit, user_currency: user_currency}}
      end
    else
      {:unit, {:error, :not_found}} -> {:error, :not_found}
      {:unit_owned, false} -> {:error, :not_owned}
      {:can_tier_up, false} -> {:error, :cant_tier_up}
      {:can_afford, false} -> {:error, :cant_afford}
    end
  end

  @doc """
  Returns whether a unit can tier up. tier is blocked by rank.
  """
  def can_tier_up(unit), do: can_tier_up(unit.rank, unit.tier)

  # TODO: Don't allow units with a level lower than the tier's max to tier up [#CHoM-227]
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

  Returns a `%CurrencyCost{}` list.
  """
  def calculate_tier_up_cost(unit),
    do: [
      %CurrencyCost{
        currency_id: Currencies.get_currency_by_name!("Gold").id,
        amount: unit.level |> Math.pow(2) |> round()
      },
      %CurrencyCost{currency_id: Currencies.get_currency_by_name!("Gems").id, amount: 50}
    ]

  ##########
  # Fusion #
  ##########

  @doc """
  Consume a list of units that meet specific rank and character requirements based on the target
  unit's rank in order to increase it.

  Returns `{:ok, unit}` or `{:error, reason}`.
  """
  def fuse(user_id, unit_id, consumed_units_ids) do
    with {:unit, {:ok, unit}} <- {:unit, Units.get_unit(unit_id)},
         {:unit_owned, true} <- {:unit_owned, unit.user_id == user_id},
         {:can_rank_up, true} <- {:can_rank_up, can_rank_up(unit)},
         {:unit_not_in_consumed_units, true} <-
           {:unit_not_in_consumed_units, unit_id not in consumed_units_ids},
         consumed_units <- Units.get_units_by_ids(consumed_units_ids),
         {:consumed_units_owned, true} <-
           {:consumed_units_owned, Enum.all?(consumed_units, &(&1.user_id == user_id))},
         {:consumed_units_count, true} <-
           {:consumed_units_count, Enum.count(consumed_units) == Enum.count(consumed_units_ids)},
         {:consumed_units_valid, true} <-
           {:consumed_units_valid, meets_fuse_requirements?(unit, consumed_units)} do
      result =
        Multi.new()
        |> Multi.run(:unit, fn _, _ -> Units.add_rank(unit) end)
        |> Multi.run(:deleted_units, fn _, _ -> delete_consumed_units(consumed_units_ids) end)
        |> Transaction.run()

      case result do
        {:error, reason} ->
          {:error, reason}

        {:error, _, _, _} ->
          {:error, :transaction}

        {:ok, %{unit: unit}} ->
          {:ok, unit}
      end
    else
      {:unit, {:error, :not_found}} ->
        {:error, :not_found}

      {:unit_owned, false} ->
        {:error, :not_owned}

      {:can_rank_up, false} ->
        {:error, :cant_rank_up}

      {:unit_not_in_consumed_units, false} ->
        {:error, :consumed_units_invalid}

      {:consumed_units_owned, false} ->
        {:error, :consumed_units_not_found}

      {:consumed_units_count, false} ->
        {:error, :consumed_units_not_found}

      {:consumed_units_valid, false} ->
        {:error, :consumed_units_invalid}
    end
  end

  defp delete_consumed_units(unit_ids) do
    {amount_deleted, _return} = Units.delete_units(unit_ids)

    if Enum.count(unit_ids) == amount_deleted, do: {:ok, amount_deleted}, else: {:error, "failed"}
  end

  defp meets_fuse_requirements?(unit, unit_list) do
    {same_character_amount, same_character_rank} = same_character_requirements(unit)
    {same_faction_amount, same_faction_rank} = same_faction_requirements(unit)

    with {:ok, removed_same_character} <-
           remove_same_character(unit, unit_list, same_character_amount, same_character_rank),
         {:ok, removed_same_faction} <-
           remove_same_faction(
             unit,
             removed_same_character,
             same_faction_amount,
             same_faction_rank
           ) do
      # If we got here with an empty list, then the units are valid
      if Enum.empty?(removed_same_faction), do: true, else: false
    else
      :error -> false
    end
  end

  defp same_character_requirements(%Unit{rank: @star4}), do: {2, @star4}
  defp same_character_requirements(%Unit{rank: @star5}), do: {1, @star5}
  defp same_character_requirements(%Unit{rank: @illumination1}), do: {1, @star5}
  defp same_character_requirements(%Unit{rank: @illumination2}), do: {1, @star5}
  defp same_character_requirements(%Unit{rank: @illumination3}), do: {3, @star5}

  defp same_faction_requirements(%Unit{rank: @star4}), do: {4, @star4}
  defp same_faction_requirements(%Unit{rank: @star5}), do: {4, @star5}
  defp same_faction_requirements(%Unit{rank: @illumination1}), do: {1, @illumination1}
  defp same_faction_requirements(%Unit{rank: @illumination2}), do: {2, @illumination2}
  defp same_faction_requirements(%Unit{rank: @illumination3}), do: {2, @illumination2}

  defp remove_same_character(unit, unit_list, amount, rank) do
    Enum.reduce_while(1..amount, unit_list, fn _, list ->
      same_character =
        Enum.find(
          list,
          &(&1.character_id == unit.character_id and &1.rank == rank)
        )

      if is_nil(same_character) do
        # Not enough of same character
        {:halt, :error}
      else
        {:cont, List.delete(list, same_character)}
      end
    end)
    |> case do
      :error -> :error
      list -> {:ok, list}
    end
  end

  defp remove_same_faction(unit, unit_list, amount, rank) do
    Enum.reduce_while(1..amount, unit_list, fn _, list ->
      same_character =
        Enum.find(
          list,
          &(&1.character.faction == unit.character.faction and &1.rank == rank)
        )

      if is_nil(same_character) do
        # Not enough of same faction
        {:halt, :error}
      else
        {:cont, List.delete(list, same_character)}
      end
    end)
    |> case do
      :error -> :error
      list -> {:ok, list}
    end
  end

  @doc """
  Returns whether a unit can rank up, based on its current rank and its character's quality.
  """
  def can_rank_up(%Unit{rank: rank, character: %Character{quality: @epic}}), do: rank < @awakened

  def can_rank_up(%Unit{rank: rank, character: %Character{quality: @rare}}),
    do: rank < @illumination2

  def can_rank_up(_unit), do: false

  ##########
  # Battle #
  ##########

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

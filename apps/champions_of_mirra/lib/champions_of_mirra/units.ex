defmodule ChampionsOfMirra.Units do
  def select_unit(_user_id, _unit_id, slot) when slot > 4, do: {:error, :out_of_bounds}

  def select_unit(user_id, unit_id, slot) do
    if Units.get_selected_units(user_id) |> Enum.any?(&(&1.slot == slot)) do
      {:error, :slot_occupied}
    else
      {:ok, _unit} =
        Units.get_unit(unit_id)
        |> Units.update_selected(%{selected: true, slot: slot})

      :ok
    end
  end

  def unselect_unit(unit_id) do
    {:ok, _unit} =
      Units.get_unit(unit_id)
      |> Units.update_selected(%{selected: false, slot: nil})

    :ok
  end
end

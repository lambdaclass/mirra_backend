defmodule Arena.Game.Crate do
  @moduledoc """
  Module to handle crate logic
  """
  def take_damage(crate, damage, damage_owner_id) do
    crate =
      update_in(crate, [:aditional_info, :health], fn current_health -> max(current_health - damage, 0) end)

    unless alive?(crate) do
      send(self(), {:crate_destroyed, damage_owner_id, crate.id})
    end

    crate
  end

  def alive?(crate) do
    crate.aditional_info.health > 0
  end

  def interactable_crates(crates) do
    Map.filter(crates, fn {_crate_id, crate} -> alive?(crate) end)
  end
end

defmodule Arena.Game.Crate do
  @moduledoc """
  Module to handle crate logic
  """
  def take_damage(crate, damage) do
    update_in(crate, [:aditional_info, :health], fn current_health -> max(current_health - damage, 0) end)
  end

  def alive?(crate) do
    crate.aditional_info.health > 0
  end

  def interactable_crates(crates) do
    Map.filter(crates, fn {_crate_id, crate} -> crate.aditional_info.status != :DESTROYED end)
  end
end

defmodule DarkWoldsServer.Autobattle do
  alias DarkWorldsServer.Units

  def run_battle(user_1, user_2) do
    user_1_units = Units.get_selected_units(user_1)
    user_2_units = Units.get_selected_units(user_2)

    user_1_agg_level = Enum.reduce(user_1_units, 0, fn unit, acc -> acc + unit.level end)
    user_2_agg_level = Enum.reduce(user_2_units, 0, fn unit, acc -> acc + unit.level end)
    total_level = user_1_agg_level + user_2_agg_level

    if Enum.random(1..total_level) <= user_1_agg_level, do: user_1, else: user_2
  end
end

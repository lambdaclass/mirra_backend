defmodule DarkWorldsServer.Autobattle do
  alias DarkWorldsServer.Units

  @doc """
  Run an automatic battle between two users. The outcome is decided randomly, favoring the player
  with the higher aggregate level of their selected units. Only validation done is for empty teams.

  Returns the id of the winner.
  """
  def run_battle(user_1, user_2) do
    user_1_units = Units.get_selected_units(user_1)
    user_2_units = Units.get_selected_units(user_2)

    cond do
      user_1_units == [] ->
        {:error, {:user_1, :no_selected_units}}

      user_2_units == [] ->
        {:error, {:user_2, :no_selected_units}}

      true ->
        user_1_agg_level = Enum.reduce(user_1_units, 0, fn unit, acc -> acc + unit.level end)
        user_2_agg_level = Enum.reduce(user_2_units, 0, fn unit, acc -> acc + unit.level end)
        total_level = user_1_agg_level + user_2_agg_level

        if Enum.random(1..total_level) <= user_1_agg_level, do: user_1, else: user_2
    end
  end
end

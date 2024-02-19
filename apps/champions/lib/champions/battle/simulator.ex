defmodule Champions.Battle.Simulator do
  @moduledoc """
  Runs battles.
  """
  alias Champions.Units
  alias GameBackend.Units.Unit

  require Logger

  @maximum_ticks 500

  def run_battle(team_1, team_2) do
    unit_ids = team_1 + team_2

    team_1 = Enum.into(team_1, %{team: 1}, &create_unit/1)
    team_2 = Enum.into(team_1, %{team: 2}, &create_unit/1)
    units = Map.merge(team_1, team_2)

    Enum.reduce_while(1..@maximum_ticks, units, fn tick, units ->
      new_state =
        Enum.reduce(unit_ids, units, fn unit, units ->
          Logger.log(:info, "Process tick #{tick} for unit #{unit}")
          process_tick(unit, units)
        end)

      check_winner(new_state, tick)
    end)
  end

  def process_tick(_unit, units) do
    units
  end

  def check_winner(units, tick) do
    winner =
      cond do
        Enum.all?(units, &(&1.team == 1)) -> :team_1
        Enum.all?(units, &(&1.team == 2)) -> :team_2
        true -> :none
      end

    case winner do
      :team_1 ->
        {:halt, :team_1}

      :team_2 ->
        {:halt, :team_2}

      :none ->
        if tick == @maximum_ticks,
          # Challenger didn't win in the max time, so he lost
          do: {:halt, :team_2},
          else: {:cont, units}
    end
  end

  defp create_unit(%Unit{character: character} = unit),
    do:
      {unit.id,
       %{
         max_health: Units.get_max_health(unit),
         health: Units.get_max_health(unit),
         attack: Units.get_attack(unit),
         speed: Units.get_speed(unit),
         armor: Units.get_armor(unit),
         faction: character.faction,
         # class: character.class,
         basic_skill: character.basic_skill,
         ultimate_skill: character.ultimate_skill,
         energy: 0,
         ticks_to_next_attack: character.speed,
         target_strategy: character.target_strategy
       }}
end

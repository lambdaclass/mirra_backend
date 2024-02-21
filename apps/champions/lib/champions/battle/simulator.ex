defmodule Champions.Battle.Simulator do
  @moduledoc """
  Runs battles.
  """
  alias GameBackend.Units.Skills.Effect
  alias GameBackend.Units.Skill
  alias Champions.Units
  alias GameBackend.Units.Unit

  require Logger

  @maximum_steps 500

  @doc """
  user_1 = Champions.Users.register("User1")
  user_2 = Champions.Users.register("User2")
  team1 = Enum.map(1..6, fn slot -> GameBackend.Units.insert_unit(%{character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id, unit_level: 1, tier: 1, rank: 1, selected: true, user_id: user_1.id, slot: slot}) |> elem(1) |> GameBackend.Repo.preload(character: [:basic_skill, :ultimate_skill]) end)
  team2 = Enum.map(1..6, fn slot -> GameBackend.Units.insert_unit(%{character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id, unit_level: 1, tier: 1, rank: 1, selected: true, user_id: user_2.id, slot: slot}) |> elem(1) |> GameBackend.Repo.preload(character: [:basic_skill, :ultimate_skill]) end)
  Champions.Battle.Simulator.run_battle team1, team2
  """
  def run_battle(team_1, team_2) do
    unit_ids = team_1 ++ team_2

    team_1 = Enum.into(team_1, %{}, fn unit -> create_unit_map(unit, 1) end)
    team_2 = Enum.into(team_2, %{}, fn unit -> create_unit_map(unit, 2) end)
    units = Map.merge(team_1, team_2)

    Enum.reduce_while(1..@maximum_steps, units, fn step, units ->
      new_state =
        Enum.reduce(unit_ids, units, fn unit, units ->
          IO.inspect("Process step #{step} for unit #{unit.id}")
          process_step(unit, units)
        end)

      check_winner(new_state, step)
    end)
  end

  def process_step(_unit, units) do
    units
  end

  def check_winner(units, step) do
    winner =
      cond do
        Enum.all?(units, fn {_id, unit} -> unit.team == 1 end) -> :team_1
        Enum.all?(units, fn {_id, unit} -> unit.team == 2 end) -> :team_2
        true -> :none
      end

    case winner do
      :team_1 ->
        {:halt, :team_1}

      :team_2 ->
        {:halt, :team_2}

      :none ->
        if step == @maximum_steps,
          # Challenger didn't win in the max time, so he lost
          do: {:halt, :team_2},
          else: {:cont, units}
    end
  end

  defp create_unit_map(%Unit{character: character} = unit, team), do:
      {unit.id,
       %{
         max_health: Units.get_max_health(unit),
         health: Units.get_max_health(unit),
         attack: Units.get_attack(unit),
         armor: Units.get_armor(unit),
         faction: character.faction,
         # class: character.class,
         basic_skill: create_skill_map(character.basic_skill),
         ultimate_skill: create_skill_map(character.ultimate_skill),
         energy: 0,
         team: team
       }}

  defp create_skill_map(%Skill{} = skill), do:
    %{
      targeting_strategy: skill.targeting_strategy,
      amount_of_targets: skill.amount_of_targets,
      effects: Enum.map(skill.effects, &create_effect_map/1)
    }

  defp create_effect_map(%Effect{} = effect), do:
  %{
    type: effect.type,
    stat: effect.stat,
    based_on_stat: effect.based_on_stat,
    amount: effect.amount,
    application_type: effect.application_type
  }
end

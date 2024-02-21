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
  team1 = Enum.map([1], fn slot -> GameBackend.Units.insert_unit(%{character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id, unit_level: 1, tier: 1, rank: 1, selected: true, user_id: user_1.id, slot: slot}) |> elem(1) |> GameBackend.Repo.preload(character: [:basic_skill, :ultimate_skill]) end)
  team2 = Enum.map([1], fn slot -> GameBackend.Units.insert_unit(%{character_id: GameBackend.Units.Characters.get_character_by_name("Muflus").id, unit_level: 1, tier: 1, rank: 1, selected: true, user_id: user_2.id, slot: slot}) |> elem(1) |> GameBackend.Repo.preload(character: [:basic_skill, :ultimate_skill]) end)
  Champions.Battle.Simulator.run_battle team1, team2
  """
  def run_battle(team_1, team_2) do
    unit_ids = Enum.map(team_1 ++ team_2, fn unit -> unit.id end)

    team_1 = Enum.into(team_1, %{}, fn unit -> create_unit_map(unit, 1) end)
    team_2 = Enum.into(team_2, %{}, fn unit -> create_unit_map(unit, 2) end)
    units = Map.merge(team_1, team_2)

    Enum.reduce_while(1..@maximum_steps, units, fn step, initial_step_state ->
      new_state =
        units
        |> Enum.map(fn {id, _unit} -> id end)
        |> Enum.take_random(Enum.count(unit_ids))
        |> Enum.reduce(initial_step_state, fn unit_id, current_state ->
          IO.inspect("Process step #{step} for unit #{unit_id}")
          process_step(initial_step_state[unit_id], initial_step_state, current_state)
        end)

      IO.inspect(
        new_state
        |> Enum.map(fn {_id, unit} ->
          Map.take(unit, [:id, :health, :energy])
          |> Map.put(:skill_cooldown, unit.basic_skill.remaining_cooldown)
        end),
        label: :new_state
      )

      remove_dead_units(new_state)
      |> check_winner(step)
    end)
  end

  # initial_step_state: List of units. What we base our decisions on.
  # current_state: List of units. What we actually modify.
  defp process_step(unit, initial_step_state, current_state) do
    new_state =
      cond do
        not can_attack(unit) ->
          current_state

        can_cast_ultimate(unit) ->
          IO.inspect("#{unit.id} casting ULTIMATE skill")
          unit
          |> cast_skill(unit.ultimate_skill, initial_step_state, current_state)
          |> put_in([unit.id, :energy], 0)

        can_cast_basic(unit) ->
          IO.inspect("#{unit.id} casting basic skill")
          new_state = cast_skill(unit, unit.basic_skill, initial_step_state, current_state)

          new_state
          |> put_in(
            [unit.id, :basic_skill, :remaining_cooldown],
            unit.basic_skill.base_cooldown + 1
          )
          |> put_in([unit.id, :energy], new_state[unit.id][:energy] + 75)

        true ->
          current_state
      end

    put_in(
      new_state,
      [unit.id, :basic_skill, :remaining_cooldown],
      max(new_state[unit.id].basic_skill.remaining_cooldown - 1, 0)
    )

    # decrease_effects_remaining_steps(unit, current_state)
  end

  defp remove_dead_units(units),
    do: Enum.filter(units, fn {_id, unit} -> unit.health > 0 end) |> Enum.into(%{})

  defp check_winner(units, step) do
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
          do: {:halt, :timeout},
          else: {:cont, units}
    end
  end

  # Is immobilized?
  defp can_attack(_unit), do: true

  # Has energy?
  defp can_cast_ultimate(unit), do: unit.energy >= 500

  # Is cooldown ready?
  defp can_cast_basic(unit), do: unit.basic_skill.remaining_cooldown <= 0

  defp cast_skill(unit, skill, initial_step_state, current_state) do
    Enum.reduce(skill.effects, current_state, fn effect, new_state ->
      target_ids = choose_targets(unit, effect, initial_step_state)

      targets_after_effect =
        Enum.map(target_ids, fn id -> apply_effect(effect, unit, new_state[id]) end)

      Enum.reduce(targets_after_effect, new_state, fn target_unit, acc_state ->
        Map.put(acc_state, target_unit.id, target_unit)
      end)
    end)
  end

  defp choose_targets(
         %{team: team},
         %{
           targeting_strategy: "random",
           targets_allies: targets_allies,
           amount_of_targets: amount
         } =
           _effect,
         state
       ),
       do:
         state
         |> Enum.filter(fn {_id, unit} -> unit.team == team == targets_allies end)
         |> Enum.take_random(amount)
         |> Enum.map(fn {id, _unit} -> id end)

  defp apply_effect(%{type: "instant"} = effect, caster, target) do
    new_value = calculate_value(effect, caster, target)
    Map.put(target, String.to_atom(effect.stat_affected), new_value)
  end

  defp calculate_value(
         %{amount_format: "additive", stat_based_on: nil} = effect,
         _caster,
         target
       ),
       do: target[String.to_atom(effect.stat_affected)] + effect.amount

  defp calculate_value(
         %{amount_format: "multiplicative", stat_based_on: nil} = effect,
         _caster,
         target
       ),
       do: target[String.to_atom(effect.stat_affected)] * effect.amount

  defp calculate_value(
         %{amount_format: "additive", stat_based_on: stat_based_on} = effect,
         caster,
         target
       ),
       do:
         target[String.to_atom(effect.stat_affected)] +
           effect.amount * caster[String.to_atom(stat_based_on)] / 100

  defp create_unit_map(%Unit{character: character} = unit, team),
    do:
      {unit.id,
       %{
         id: unit.id,
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

  defp create_skill_map(%Skill{} = skill),
    do: %{
      effects: Enum.map(skill.effects, &create_effect_map/1),
      base_cooldown: skill.cooldown,
      remaining_cooldown: skill.cooldown
    }

  defp create_effect_map(%Effect{} = effect),
    do: %{
      type: effect.type,
      stat_affected: effect.stat_affected,
      stat_based_on: effect.stat_based_on,
      amount: effect.amount,
      amount_format: effect.amount_format,
      targeting_strategy: effect.targeting_strategy,
      amount_of_targets: effect.amount_of_targets,
      targets_allies: effect.targets_allies
    }
end

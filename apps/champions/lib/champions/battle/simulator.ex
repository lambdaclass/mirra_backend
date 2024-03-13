defmodule Champions.Battle.Simulator do
  @moduledoc """
  Runs battles.

  Units have stats that are calculated on battle start (Attack, Max Health, Defense), as well as two skills.
  The ultimate has no cooldown and it's cast whenever a unit reaches 500 energy.

  The primary skill has a cooldown and it's cast when it's available if the ultimate is not. Each skill has a
  set amount of energy gained on cast.

  Skills group many effects under a same cooldown and cast.
  These effects are made of different parts that define how it behaves: `Modifiers`, `Components` and `Executions`.

  They have different application types (checked are implemented):
  [x] Instant - Applied once, irreversible.
  [ ] Duration - Applied once and reverted once its duration ends.
  [ ] Permanent - Applied once, is stored in the unit so that it can be reversed (with a dispel, for example)

  They also have different targeting strategies:
  [x] Random
  [ ] Nearest
  [ ] Furthest
  [ ] Frontline - Heroes in slots 1 and 2
  [ ] Backline - Heroes in slots 2 to 4
  [ ] Factions
  [ ] Classes
  [ ] Highest (stat)
  [ ] Lowest (stat)

  Two units can attack the same unit at the same time and over-kill them. This is expected behavior that results
  from having the battle be simultaneous.

  """
  alias GameBackend.Units.Skills.Effect
  alias GameBackend.Units.Skill
  alias Champions.Units
  alias GameBackend.Units.Unit

  require Logger

  @maximum_steps 500
  @ultimate_energy_cost 500

  @doc """
  Runs a battle between two teams.
  Teams are expected to be lists of units with their character and their skills preloaded.

  Returns `:team_1`, `:team_2`, `:tie` or `:timeout`.

  ## Examples

      iex> team_1 = Enum.map(user1.units, GameBackend.Repo.preload([character: [:basic_skill, :ultimate_skill]]))
      iex> team_2 = Enum.map(user2.units, GameBackend.Repo.preload([character: [:basic_skill, :ultimate_skill]]))
      iex> run_battle(team_1, team_2)
      :team_1
  """
  def run_battle(team_1, team_2, seed \\ 1) do
    :rand.seed(:default, seed)
    team_1 = Enum.into(team_1, %{}, fn unit -> create_unit_map(unit, 1) end)
    team_2 = Enum.into(team_2, %{}, fn unit -> create_unit_map(unit, 2) end)
    units = Map.merge(team_1, team_2)

    # The initial_step_state is what allows the battle to be simultaneous. If we refreshed the accum on every action,
    # we would be left with a turn-based battle. Instead we take decisions based on the state of the battle at the beggining
    # of the step regardless of the changes that happened "before" (execution-wise) in this step.
    Enum.reduce_while(1..@maximum_steps, units, fn step, initial_step_state ->
      new_state =
        initial_step_state
        |> Enum.map(fn {id, _unit} -> id end)
        |> Enum.reduce(initial_step_state, fn unit_id, current_state ->
          process_step(initial_step_state[unit_id], initial_step_state, current_state)
        end)

      remove_dead_units(new_state)
      |> check_winner(step)
    end)
  end

  defp process_step(unit, initial_step_state, current_state) do
    new_state =
      cond do
        not can_attack(unit) ->
          current_state

        can_cast_ultimate_skill(unit) ->
          new_state = cast_skill(unit.ultimate_skill, unit, initial_step_state, current_state)
          put_in(new_state, [unit.id, :energy], 0)

        can_cast_basic_skill(unit) ->
          new_state = cast_skill(unit.basic_skill, unit, initial_step_state, current_state)

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

    # TODO: decrease_effects_remaining_steps(unit, current_state)
  end

  defp remove_dead_units(units),
    do: Enum.filter(units, fn {_id, unit} -> unit.health > 0 end) |> Enum.into(%{})

  defp check_winner(units, step) do
    winner =
      cond do
        Enum.empty?(units) -> :tie
        Enum.all?(units, fn {_id, unit} -> unit.team == 2 end) -> :team_2
        Enum.all?(units, fn {_id, unit} -> unit.team == 1 end) -> :team_1
        true -> :none
      end

    case winner do
      :none ->
        if step == @maximum_steps,
          do: {:halt, :timeout},
          else: {:cont, units}

      result ->
        {:halt, result}
    end
  end

  # TODO: Is immobilized?
  defp can_attack(_unit), do: true

  # Has enough energy?
  defp can_cast_ultimate_skill(unit), do: unit.energy >= @ultimate_energy_cost

  # Is cooldown ready?
  defp can_cast_basic_skill(unit), do: unit.basic_skill.remaining_cooldown <= 0

  defp cast_skill(skill, caster, initial_step_state, current_state) do
    new_state =
      Enum.reduce(skill.effects, current_state, fn effect, new_state ->
        target_ids = choose_targets(caster, effect, initial_step_state)

        targets_after_effect = Enum.map(target_ids, fn id -> maybe_apply_effect(effect, caster, new_state[id]) end)

        Enum.reduce(targets_after_effect, new_state, fn target, acc_state ->
          Map.put(acc_state, target.id, target)
        end)
      end)

    new_caster = Map.put(caster, :energy, caster.energy + skill.energy_regen)

    Map.put(new_state, caster.id, new_caster)
  end

  defp choose_targets(
         %{team: team},
         %{
           target_count: count,
           target_strategy: "random",
           target_allies: target_allies
         } = _effect,
         state
       ),
       do:
         state
         |> Enum.filter(fn {_id, unit} -> unit.team == team == target_allies end)
         |> Enum.take_random(count)
         |> Enum.map(fn {id, _unit} -> id end)

  defp maybe_apply_effect(effect, target, caster) do
    if effect_hits?(effect),
      do: apply_effect(effect, target, caster),
      else: target
  end

  defp effect_hits?(effect) do
    chance_to_apply_component =
      Enum.find(effect.components, fn comp ->
        case comp do
          %{"type" => "ChanceToApply"} -> true
          _ -> false
        end
      end)

    case chance_to_apply_component do
      nil ->
        true

      chance_to_apply_component ->
        chance_to_apply_component["chance"] >= :rand.uniform()
    end
  end

  defp apply_effect(effect, target, caster) do
    # TODO
    target_after_modifiers = target

    target_after_executions =
      Enum.reduce(effect.executions, target_after_modifiers, fn execution, target ->
        process_execution(execution, target, caster)
      end)

    target_after_executions
  end

  defp process_execution(
         %{
           "type" => "DealDamage",
           "attack_ratio" => attack_ratio,
           "energy_recharge" => energy_recharge,
           # TODO
           "delay" => _delay
         },
         target,
         caster
       ) do
    target
    |> Map.put(:health, target.health + floor(attack_ratio * caster.attack / 100))
    |> Map.put(:energy, max(target.energy + energy_recharge, 500))
  end

  defp create_unit_map(%Unit{character: character} = unit, team),
    do:
      {unit.id,
       %{
         id: unit.id,
         max_health: Units.get_max_health(unit),
         health: Units.get_max_health(unit),
         attack: Units.get_attack(unit),
         defense: Units.get_defense(unit),
         faction: character.faction,
         # class: character.class,
         basic_skill: create_skill_map(character.basic_skill),
         ultimate_skill: create_skill_map(character.ultimate_skill),
         energy: 0,
         team: team,
         modifiers: []
       }}

  defp create_skill_map(%Skill{} = skill),
    do: %{
      name: skill.name,
      effects: Enum.map(skill.effects, &create_effect_map/1),
      base_cooldown: skill.cooldown,
      remaining_cooldown: skill.cooldown,
      energy_regen: skill.energy_regen
    }

  defp create_effect_map(%Effect{} = effect),
    do: %{
      type: effect.type,
      initial_delay: effect.initial_delay,
      target_count: effect.target_count,
      target_strategy: effect.target_strategy,
      target_allies: effect.target_allies,
      target_attribute: effect.target_attribute,
      executions: effect.executions
    }
end

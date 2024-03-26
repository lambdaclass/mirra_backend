defmodule Champions.Battle.Simulator do
  @moduledoc """
  Runs battles.

  Units have stats that are calculated on battle start (Attack, Max Health, Defense), as well as two skills. The ultimate
  has no cooldown and it's cast whenever a unit reaches 500 energy. Energy is gained whenever the target attacks.
  The primary skill has a cooldown and it's cast when it's available if the ultimate is not.

  Skills possess many effects with their own targets. Effects are composed of `Components`, `Modifiers` and
  `Executions` (check module docs for more info on each).

  They have different application types (checked are implemented):
  [x] Instant - Applied once, irreversible.
  [ ] Permanent - Applied once, is stored in the unit so that it can be reversed (with a dispel, for example)
  [ ] Duration - Applied once and reverted once its duration ends.

  They also have different targeting strategies:
  [x] Random
  [ ] Nearest
  [ ] Furthest
  [ ] Frontline - Heroes in slots 1 and 2
  [ ] Backline - Heroes in slots 2 to 4
  [ ] Factions
  [ ] Classes
  [ ] Min (STAT)
  [ ] Max (STAT)

  And different ways in which their amount is interpreted:
  [x] Additive
  [x] Multiplicative
  [x] Additive & based on stat - The amount is a % of one of the caster's stats
  [ ] Multiplicative & based on stat?

  Two units can attack the same unit at the same time and over-kill it. This is expected behavior that results
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

    initial_state = %{units: units, skills_being_cast: [], pending_effects: [], pending_executions: []}

    # The initial_step_state is what allows the battle to be simultaneous. If we refreshed the accum on every action,
    # we would be left with a turn-based battle. Instead we take decisions based on the state of the battle at the beggining
    # of the step regardless of the changes that happened "before" (execution-wise) in this step.
    Enum.reduce_while(1..@maximum_steps, initial_state, fn step, initial_step_state ->
      initial_step_state = Map.put(initial_step_state, :step_number, step)

      new_state =
        Enum.reduce(initial_step_state.units, initial_step_state, fn {unit_id, unit}, current_state ->
          Logger.info("Process step #{step} for unit #{format_unit_name(unit)}")
          process_step_for_unit(initial_step_state.units[unit_id], current_state, initial_step_state)
        end)

      new_state =
        Enum.reduce(new_state.skills_being_cast, new_state, fn skill, current_state ->
          Logger.info("Process step #{step} for skill #{skill.name} cast by #{String.slice(skill.caster_id, 0..2)}")

          # We need the initial_step_state to decide effect targets
          process_step_for_skill(skill, current_state, initial_step_state)
        end)
        |> process_step_for_effects()

      Logger.info("Step #{step} finished: #{inspect(format_step_state(new_state))}")

      remove_dead_units(new_state)
      |> check_winner(step)
    end)
  end

  # Removes dead units from the battle state.
  defp remove_dead_units(state) do
    new_units =
      Enum.reduce(state.units, %{}, fn {unit_id, unit}, units ->
        if unit.health > 0 do
          Map.put(units, unit_id, unit)
        else
          Logger.info("Unit #{format_unit_name(unit)} died.")
          units
        end
      end)

    Map.put(state, :units, new_units)
  end

  # Check if the battle has ended.
  # Battle can end if all unit of a team are dead, or if the maximum step amount has been reached.
  defp check_winner(state, step) do
    winner =
      cond do
        Enum.empty?(state.units) -> :tie
        Enum.all?(state.units, fn {_id, unit} -> unit.team == 2 end) -> :team_2
        Enum.all?(state.units, fn {_id, unit} -> unit.team == 1 end) -> :team_1
        true -> :none
      end

    case winner do
      :none ->
        if step == @maximum_steps do
          Logger.info("Battle timeout.")
          {:halt, :timeout}
        else
          {:cont, state}
        end

      result ->
        Logger.info("Battle ended. Result: #{result}.")
        {:halt, result}
    end
  end

  # Calculate the new state of the battle after a step passes for a unit.
  # Updates cooldowns, casts skills and reduces self-affecting modifier durations.
  defp process_step_for_unit(unit, current_state, initial_step_state) do
    new_state =
      cond do
        not can_attack(unit, initial_step_state) ->
          Logger.info("Unit #{format_unit_name(unit)} cannot attack")
          current_state

        can_cast_ultimate_skill(unit) ->
          Logger.info("Unit #{format_unit_name(unit)} casting Ultimate skill")

          current_state
          |> Map.put(:skills_being_cast, [unit.ultimate_skill | current_state.skills_being_cast])
          |> put_in([:units, unit.id, :energy], 0)

        can_cast_basic_skill(unit) ->
          Logger.info("Unit #{format_unit_name(unit)} casting basic skill")

          current_state
          |> Map.put(:skills_being_cast, [unit.basic_skill | current_state.skills_being_cast])
          |> put_in(
            [:units, unit.id, :basic_skill, :remaining_cooldown],
            unit.basic_skill.base_cooldown + 1
          )
          |> update_in([:units, unit.id, :energy], &(&1 + unit.basic_skill.energy_regen))

        true ->
          current_state
      end

    # Reduce modifier remaining timers & remove expired ones
    new_modifiers = %{
      additives: reduce_modifier_timers(unit.modifiers.additives, unit),
      multiplicatives: reduce_modifier_timers(unit.modifiers.multiplicatives, unit),
      overrides: reduce_modifier_timers(unit.modifiers.overrides, unit)
    }

    # Reduce basic skill cooldown
    new_state
    |> put_in(
      [:units, unit.id, :basic_skill, :remaining_cooldown],
      max(new_state.units[unit.id].basic_skill.remaining_cooldown - 1, 0)
    )
    |> put_in([:units, unit.id, :modifiers], new_modifiers)
  end

  # Reduces modifier timers and removes expired ones.
  # Called when processing a step for a unit.
  defp reduce_modifier_timers(modifiers, unit) do
    Enum.reduce(modifiers, [], fn modifier, acc ->
      case modifier.remaining_steps do
        # Modifier is permanent
        -1 ->
          [modifier | acc]

        # Modifier expired
        0 ->
          Logger.info("Modifier [#{format_modifier_name(modifier)}] expired for #{format_unit_name(unit)}.")

          acc

        # Modifier still going, reduce its timer by one
        remaining ->
          Logger.info(
            "Modifier [#{format_modifier_name(modifier)}] remaining time reduced for #{format_unit_name(unit)}."
          )

          [Map.put(modifier, :remaining_steps, remaining - 1) | acc]
      end
    end)
  end

  # Calculate the new state of the battle after a step passes for a skill being cast.
  # Reduces the remaining animation and effect trigger, and casts the effects if the latter has ended.
  defp process_step_for_skill(skill, current_state, initial_step_state) do
    # Check if the casting unit has died
    if Map.has_key?(current_state.units, skill.caster_id) do
      {new_skill, new_state} = process_skill_effects_trigger_value(skill, current_state, initial_step_state)

      if new_skill.animation_duration == 0 do
        # If the animation has finished, we remove skill from list.
        Map.put(new_state, :skills_being_cast, List.delete(new_state.skills_being_cast, skill))
      else
        # Otherwise, we update it with its new state.
        new_skill = %{new_skill | animation_duration: skill.animation_duration - 1}
        Map.put(new_state, :skills_being_cast, [new_skill | List.delete(new_state.skills_being_cast, skill)])
      end
    else
      # If the unit died, just delete the skill being cast
      Logger.info("Skill caster #{String.slice(skill.caster_id, 0..2)} died. Deleting skill from list.")
      Map.put(current_state, :skills_being_cast, List.delete(current_state.skills_being_cast, skill))
    end
  end

  # Calculate the new state of the battle after a step passes for a skill being cast, specifically for its `effects_trigger` value.
  # If the effects_trigger is ready, trigger the skill's effects, adding them to the `pending_effects` in the state.
  defp process_skill_effects_trigger_value(%{effects_trigger: 0} = skill, current_state, initial_step_state) do
    Logger.info("Animation trigger for skill #{skill.name} ready. Creating #{Enum.count(skill.effects)} effects.")
    current_state = trigger_skill_effects(skill, current_state, initial_step_state)
    {%{skill | effects_trigger: -1}, current_state}
  end

  # Calculate the new state of the battle after a step passes for a skill being cast, specifically for its `effects_trigger` value.
  # If the effects have already triggered, do nothing.
  defp process_skill_effects_trigger_value(%{effects_trigger: -1} = skill, current_state, _initial_step_state),
    do: {skill, current_state}

  # Calculate the new state of the battle after a step passes for a skill being cast, specifically for its `effects_trigger` value.
  # If the effect hasn't triggered yet, reduce the remaining effects_trigger counter.
  defp process_skill_effects_trigger_value(skill, current_state, _initial_step_state) do
    {%{skill | effects_trigger: skill.effects_trigger - 1}, current_state}
  end

  # Calculate the new state of the battle after a step passes for all pending effects
  def process_step_for_effects(state) do
    {updated_pending_effects, updated_game_state} =
      Enum.reduce(state.pending_effects, {[], state}, fn effect, {new_pending_effects, current_state} ->
        # Calculate the new state of the battle after a step passes for a pending effect.
        case effect do
          %{delay: 0} ->
            # If the effect is ready to be processed, we apply it.
            Logger.info("#{format_unit_name(effect.caster)}'s effect is ready to be processed")

            targets_after_effect =
              Enum.map(effect.targets, fn id ->
                maybe_apply_effect(effect, current_state.units[id], effect.caster, current_state.step_number)
              end)

            new_state =
              Enum.reduce(targets_after_effect, current_state, fn target, acc_state ->
                put_in(acc_state, [:units, target.id], target)
              end)

            # We don't add this effect to the new_pending_effects list because it has already been applied
            {new_pending_effects, new_state}

          effect ->
            # If the effect isn't ready to be processed, we reduce its remaining delay.

            {[%{effect | delay: effect.delay - 1} | new_pending_effects], current_state}
        end
      end)

    Map.put(updated_game_state, :pending_effects, updated_pending_effects)
  end

  # Check if the unit can attack this turn.
  # For now, attacking capability is only affected by whether the unit is currently casting a skill.
  # Later on, things like stuns will be handled here.
  defp can_attack(unit, initial_step_state) do
    # Check the unit is not casting anything right now
    not Enum.any?(initial_step_state.skills_being_cast, &(&1.caster_id == unit.id))
  end

  # Check if the unit can cast their ultimate skill this step.
  defp can_cast_ultimate_skill(unit), do: unit.energy >= @ultimate_energy_cost

  # Check if the unit can cast their basic skill this step.
  defp can_cast_basic_skill(unit), do: unit.basic_skill.remaining_cooldown <= 0

  # Called when a skill being cast reaches effect_trigger 0.
  # "Queues" the effect to be processed when its delay reaches 0.
  defp trigger_skill_effects(skill, current_state, initial_step_state) do
    caster = current_state.units[skill.caster_id]

    # We store the caster's state in the effect in case the unit dies before the effect's delay ends.
    # Also, we want to calculate numbers like damage done based on the status of the caster when the effect was cast.
    effects_with_caster =
      Enum.map(skill.effects, fn effect ->
        effect |> Map.put(:caster, caster) |> Map.put(:targets, choose_targets(caster, effect, initial_step_state))
      end)

    Map.put(current_state, :pending_effects, effects_with_caster ++ current_state.pending_effects)
  end

  # Choose the targets for an effect with "random" as the strategy. Returns the target ids.
  # The `== target_allies` works as a negation operation when `target_allies` is `false`, and does nothing when `true`.
  defp choose_targets(
         %{team: team} = _caster,
         %{
           target_count: count,
           target_strategy: "random",
           target_allies: target_allies
         } = _effect,
         state
       ),
       do:
         state.units
         |> Enum.filter(fn {_id, unit} -> unit.team == team == target_allies end)
         |> Enum.take_random(count)
         |> Enum.map(fn {id, _unit} -> id end)

  # Apply an effect to its target *if it hits*.
  # Hit chance is affected by the ChanceToApply component and could be expanded later on.
  # Returns the new state of the target.
  defp maybe_apply_effect(effect, target, caster, current_step_number) do
    if effect_hits?(effect) do
      apply_effect(effect, target, caster, current_step_number)
    else
      Logger.info("#{format_unit_name(effect.caster)}'s effect missed.")
      target
    end
  end

  # Return whether an effect with a ChanceToApply component hits.
  # Later on, this might also handle similar mechanics like the target's dodge chance.
  defp effect_hits?(effect) do
    chance_to_apply_component =
      Enum.find(effect.components, fn comp -> comp["type"] == "ChanceToApply" end)

    case chance_to_apply_component do
      nil ->
        true

      chance_to_apply_component ->
        chance_to_apply_component["chance"] >= :rand.uniform()
    end
  end

  # Apply an effect to its target. Returns the new state of the target.
  # For now this applies the executions on the spot.
  # Later on, it will "cast" them as we do with skills and effects to account for execution delays.
  # Returns the new state of the target.
  defp apply_effect(effect, target, caster, current_step_number) do
    target_after_modifiers =
      Enum.reduce(effect.modifiers, target, fn modifier, target ->
        # If it's permanent, we set its duration to -1
        new_modifier =
          modifier
          |> Map.put(:remaining_steps, Map.get(effect.type, "duration", -1))
          |> Map.put(:step_applied_at, current_step_number)

        case modifier.modifier_operation do
          "Add" ->
            put_in(target, [:modifiers, :additives], [new_modifier | target.modifiers.additives])

          "Multiply" ->
            put_in(target, [:modifiers, :multiplicatives], [new_modifier | target.modifiers.multiplicatives])

          "Override" ->
            put_in(target, [:modifiers, :overrides], [new_modifier | target.modifiers.overrides])
        end
      end)

    target_after_executions =
      Enum.reduce(effect.executions, target_after_modifiers, fn execution, target_acc ->
        process_execution(execution, target_acc, caster)
      end)

    target_after_executions
  end

  # Apply a DealDamage execution to its target. Returns the new state of the target.
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
    damage = max(floor(attack_ratio * calculate_unit_stat(caster, :attack)), 0)

    Logger.info(
      "Dealing #{damage} damage to #{format_unit_name(target)} (#{target.health} -> #{target.health - damage})"
    )

    target
    |> Map.put(:health, target.health - damage)
    |> Map.put(:energy, min(target.energy + energy_recharge, @ultimate_energy_cost))
  end

  # Calculate the current amount of the given attribute that the unit has, based on its modifiers.
  defp calculate_unit_stat(unit, attribute) do
    overrides = Enum.filter(unit.modifiers.overrides, &(&1.attribute == Atom.to_string(attribute)))

    if Enum.empty?(overrides) do
      addition =
        Enum.filter(unit.modifiers.additives, &(&1.attribute == Atom.to_string(attribute)))
        |> Enum.reduce(0, fn mod, acc -> mod.float_magnitude + acc end)

      multiplication =
        Enum.filter(unit.modifiers.multiplicatives, &(&1.attribute == Atom.to_string(attribute)))
        |> Enum.reduce(1, fn mod, acc -> mod.float_magnitude * acc end)

      (unit[attribute] + addition) * multiplication
    else
      Enum.min_by(overrides, & &1.step_applied_at).float_magnitude
    end
  end

  # Used to create the initial unit maps to be used during simulation.
  defp create_unit_map(%Unit{character: character} = unit, team),
    do:
      {unit.id,
       %{
         id: unit.id,
         character_name: character.name,
         team: team,
         class: character.class,
         faction: character.faction,
         ultimate_skill: create_skill_map(character.ultimate_skill, unit.id),
         basic_skill: create_skill_map(character.basic_skill, unit.id),
         max_health: Units.get_max_health(unit),
         health: Units.get_max_health(unit),
         attack: Units.get_attack(unit),
         defense: Units.get_defense(unit),
         energy: 0,
         modifiers: %{
           additives: [],
           multiplicatives: [],
           overrides: []
         }
       }}

  # Used to create the initial skill maps to be used during simulation.
  defp create_skill_map(%Skill{} = skill, caster_id),
    do: %{
      name: skill.name,
      effects: Enum.map(skill.effects, &create_effect_map/1),
      base_cooldown: skill.cooldown,
      remaining_cooldown: skill.cooldown,
      energy_regen: skill.energy_regen || 0,
      animation_duration: skill.animation_duration || 0,
      effects_trigger: skill.animation_trigger || 0,
      caster_id: caster_id
    }

  # Used to create the initial effect maps to be used during simulation.
  defp create_effect_map(%Effect{} = effect),
    do: %{
      type: effect.type,
      delay: effect.initial_delay,
      target_count: effect.target_count,
      target_strategy: effect.target_strategy,
      target_allies: effect.target_allies,
      target_attribute: effect.target_attribute,
      components: effect.components,
      modifiers: effect.modifiers,
      executions: effect.executions
    }

  # Format step state for logs.
  defp format_step_state(%{
         units: units,
         skills_being_cast: skl,
         pending_effects: eff,
         pending_executions: exec
       }) do
    units = Enum.map(units, fn {_unit_id, unit} -> unit end)

    %{
      units:
        Enum.group_by(units, &"Team #{Map.get(&1, :team)}", fn unit ->
          %{
            unit: String.slice(unit.id, 0..2),
            health: unit.health,
            energy: unit.energy,
            cooldown: unit.basic_skill.remaining_cooldown
          }
        end),
      skills_being_cast:
        Enum.map(
          skl,
          &%{
            name: &1.name,
            animation_duration: &1.animation_duration,
            effects_trigger: &1.effects_trigger,
            caster_id: &1.caster_id
          }
        ),
      pending_effects: eff,
      pending_executions: exec
    }
  end

  # Format unit name for logs.
  defp format_unit_name(unit), do: "#{unit.character_name}-#{String.slice(unit.id, 0..2)}"

  # Format modifier name for logs.
  defp format_modifier_name(modifier),
    do: "#{modifier.modifier_operation} #{modifier.attribute} by #{modifier.float_magnitude}"
end

defmodule Champions.Battle.Simulator do
  @moduledoc """
  Runs battles.

  Units have stats that are calculated on battle start (Attack, Max Health, Defense), as well as two skills. The ultimate
  has no cooldown and it's cast whenever a unit reaches 500 energy. Energy is gained whenever the target attacks.
  The primary skill has a cooldown and it's cast when it's available if the ultimate is not.

  Skills possess effects that affect other units' or oneself's stats (the one defined in the effect's `stat_affected` field).

  They have different application types (checked are implemented):
  [x] Instant - Applied once, irreversible.
  [ ] Permanent - Applied once, is stored in the unit so that it can be reversed (with a dispel, for example)
  [ ] Duration - Applied once and reverted once its duration ends.
  [ ] Periodic - Applied many times every x number of steps for a total duration of y steps

  They also have different targeting strategies:
  [x] Random
  [ ] Nearest
  [ ] Furthest
  [ ] Min Health
  [ ] Max Health
  [ ] Min Shield
  [ ] Max Shield
  [ ] Frontline - Heroes in slots 1 and 2
  [ ] Backline - Heroes in slots 2 to 4
  [ ] Factions
  [ ] Classes

  And different ways in which their amount is interpreted:
  [x] Additive
  [x] Multiplicative
  [x] Additive & based on stat - The amount is a % of one of the caster's stats
  [ ] Multiplicative & based on stat?

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

    initial_state = %{units: units, skills_being_cast: [], pending_effects: [], pending_executions: []}

    # The initial_step_state is what allows the battle to be simultaneous. If we refreshed the accum on every action,
    # we would be left with a turn-based battle. Instead we take decisions based on the state of the battle at the beggining
    # of the step regardless of the changes that happened "before" (execution-wise) in this step.
    Enum.reduce_while(1..@maximum_steps, initial_state, fn step, initial_step_state ->
      new_state =
        Enum.reduce(initial_step_state.units, initial_step_state, fn {unit_id, unit}, current_state ->
          Logger.info("Process step #{step} for unit #{format_unit_name(unit)}")
          process_step_for_unit(initial_step_state.units[unit_id], current_state, initial_step_state)
        end)

      new_state =
        Enum.reduce(new_state.skills_being_cast, new_state, fn skill, current_state ->
          Logger.info("Process step #{step} for skill #{skill.name} cast by #{String.slice(skill.caster_id, 0..2)}")

          process_step_for_skill(skill, current_state, initial_step_state)
        end)

      new_state =
        Enum.reduce(new_state.pending_effects, new_state, fn effect, current_state ->
          Logger.info("Process step #{step} for effect cast by #{format_unit_name(effect.caster)}")

          process_step_for_effect(effect, initial_step_state, current_state)
        end)

      Logger.info("Step #{step}: #{format_step_state_for_log(new_state) |> inspect()}")

      remove_dead_units(new_state)
      |> check_winner(step)
    end)
  end

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
          |> put_in([:units, unit.id, :energy], current_state.units[unit.id].energy + unit.basic_skill.energy_regen)

        true ->
          current_state
      end

    put_in(
      new_state,
      [:units, unit.id, :basic_skill, :remaining_cooldown],
      max(new_state.units[unit.id].basic_skill.remaining_cooldown - 1, 0)
    )
  end

  defp process_step_for_skill(skill, current_state, initial_step_state) do
    # Check if the casting unit has died
    if Enum.any?(current_state.units, fn {unit_id, _unit} -> unit_id == skill.caster_id end) do
      {new_skill, new_state} = process_animation_trigger(skill, current_state, initial_step_state)

      new_skill = %{new_skill | animation_duration: skill.animation_duration - 1}

      # If the animation has finished, we remove skill from list. Otherwise, we update it with its new state.
      if new_skill.animation_duration == -1,
        do: Map.put(new_state, :skills_being_cast, List.delete(new_state.skills_being_cast, skill)),
        else: Map.put(new_state, :skills_being_cast, [new_skill | List.delete(new_state.skills_being_cast, skill)])
    else
      # If the unit died, just delete the skill being cast
      Logger.info("Skill caster #{String.slice(skill.caster_id, 0..2)} died. Deleting skill from list.")
      Map.put(current_state, :skills_being_cast, List.delete(current_state.skills_being_cast, skill))
    end
  end

  # If the animation is ready, trigger the skill effects
  defp process_animation_trigger(%{animation_trigger: 0} = skill, current_state, initial_step_state) do
    Logger.info("Animation trigger for skill #{skill.name} ready. Creating effects.")
    current_state = trigger_skill_effects(skill, current_state, initial_step_state)
    {%{skill | animation_trigger: -1}, current_state}
  end

  # If the animation has already triggered, do nothing
  defp process_animation_trigger(%{animation_trigger: -1} = skill, current_state, _initial_step_state),
    do: {skill, current_state}

  # If the animation still has not triggered, reduce the remaining counter
  defp process_animation_trigger(skill, current_state, _initial_step_state) do
    {%{skill | animation_trigger: skill.animation_trigger - 1}, current_state}
  end

  defp process_step_for_effect(%{delay: 0} = effect, initial_step_state, current_state) do
    target_ids = choose_targets(effect.caster, effect, initial_step_state)

    targets_after_effect =
      Enum.map(target_ids, fn id ->
        maybe_apply_effect(effect, current_state.units[id], effect.caster)
      end)

    current_state =
      Enum.reduce(targets_after_effect, current_state, fn target, acc_state ->
        put_in(acc_state, [:units, target.id], target)
      end)

    Map.put(current_state, :pending_effects, List.delete(current_state.pending_effects, effect))
  end

  defp process_step_for_effect(effect, _initial_step_state, current_state) do
    Map.put(current_state, :pending_effects, [
      %{effect | delay: effect.delay - 1} | List.delete(current_state.pending_effects, effect)
    ])
  end

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
        if step == @maximum_steps,
          do: {:halt, :timeout},
          else: {:cont, state}

      result ->
        {:halt, result}
    end
  end

  # Is already casting? Is stunned?
  defp can_attack(unit, initial_step_state) do
    # Check the unit is not casting anything right now
    not Enum.any?(initial_step_state.skills_being_cast, &(&1.caster_id == unit.id))
  end

  # Has enough energy?
  defp can_cast_ultimate_skill(unit), do: unit.energy >= @ultimate_energy_cost

  # Is cooldown ready?
  defp can_cast_basic_skill(unit), do: unit.basic_skill.remaining_cooldown <= 0

  defp trigger_skill_effects(skill, current_state, initial_step_state) do
    caster = current_state.units[skill.caster_id]

    # We store the caster's state in the effect in case the unit dies before the effect's delay ends
    effects_with_caster =
      Enum.map(skill.effects, fn effect ->
        effect |> Map.put(:caster, caster) |> Map.put(:targets, choose_targets(caster, effect, initial_step_state))
      end)

    Map.put(current_state, :pending_effects, effects_with_caster ++ current_state.pending_effects)
  end

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

  defp maybe_apply_effect(effect, target, caster) do
    if effect_hits?(effect),
      do: apply_effect(effect, target, caster),
      else: target
  end

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

  defp apply_effect(effect, target, caster) do
    # TODO
    target_after_modifiers = target

    target_after_executions =
      Enum.reduce(effect.executions, target_after_modifiers, fn execution, target_acc ->
        process_execution(execution, target_acc, caster)
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
    damage = floor(attack_ratio * caster.attack)

    Logger.info(
      "Dealing #{damage} damage to #{format_unit_name(target)} (#{target.health} -> #{target.health - damage})"
    )

    target
    |> Map.put(:health, target.health - damage)
    |> Map.put(:energy, min(target.energy + energy_recharge, @ultimate_energy_cost))
  end

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
         modifiers: []
       }}

  defp create_skill_map(%Skill{} = skill, caster_id),
    do: %{
      name: skill.name,
      effects: Enum.map(skill.effects, &create_effect_map/1),
      base_cooldown: skill.cooldown,
      remaining_cooldown: skill.cooldown,
      energy_regen: skill.energy_regen || 0,
      animation_duration: skill.animation_duration || 0,
      animation_trigger: skill.animation_trigger || 0,
      caster_id: caster_id
    }

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

  defp format_step_state_for_log(%{
         units: units,
         skills_being_cast: skl,
         pending_effects: eff,
         pending_executions: _exec
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
            animation_trigger: &1.animation_trigger,
            caster_id: &1.caster_id
          }
        ),
      pending_effects: eff
      #  pending_executions: exec
    }
  end

  defp format_unit_name(unit), do: "#{unit.character_name}-#{String.slice(unit.id, 0..2)}"
end

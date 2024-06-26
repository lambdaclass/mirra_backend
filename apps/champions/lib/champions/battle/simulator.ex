defmodule Champions.Battle.Simulator do
  @moduledoc """
  Runs battles.

  Units have stats that are calculated on battle start (Attack, Max Health, Defense), as well as two skills. The ultimate
  has no cooldown and it's cast whenever a unit reaches 500 energy. Energy is gained whenever the target attacks.
  The primary skill has a cooldown and it's cast when it's available if the ultimate is not.

  Skills possess many mechanics. The only implemented mechanic right now is `ApplyEffectsTo`, which is composed of many effects
  and a targeting strategy. Effects are composed of `Components`, `Modifiers`, `Executions` and `ExecutionsOverTime` (check docs for more info on each).

  ### ApplyEffectsTo mechanics

  Effects have different application types:
  [x] Instant - Applied once, irreversible.
  [x] Permanent - Applied once, is stored in the unit so that it can be reversed (with a dispel, for example)
  [x] Duration - Applied once and reverted once its duration ends.
  [ ] Periodic - Applied every X steps  until duration ends.

  The different targeting strategies are:
  [x] Random
  [x] Nearest
  [x] Furthest
  [x] Frontline - Heroes in slots 1 and 2
  [x] Backline - Heroes in slots 2 to 4
  [x] All
  [x] Self
  [ ] Factions
  [ ] Classes
  [x] Lowest (STAT)
  [x] Highest (STAT)

  It can also be chosen how many targets are affected by the effect, and if they are allies or enemies.


  ### Simultaneous Battles

  Two units can attack the same unit at the same time and over-kill it. This is expected behavior that results
  from having the battle be simultaneous. If this weren't the case, the battle would be turn-based, since a unit
  would base its actions on the state of the battle at the end of the previous unit's action.

  ### Speed Stat

  Units have a `speed` stat that affects the cooldown of their basic skill. The formula is:
  `FINAL_CD = BASE_CD / [1 + MAX(-99, SPEED) / 100]`
  For now, speed is only used to calculate the cooldown of newly cast skills, meaning it's not retroactive with
  skills already on cooldown.

  ### History

  A "history" is built as the battle progresses. This history is used to animate the battle in the client. The history
  is a list of maps, each map representing a step in the battle. Each step has a `step_number` and a list of `actions`.
  These are all translated into Protobuf messages, together with the initial state of the battle and the result,
  and then sent to the client.
  """
  alias Champions.Units
  alias GameBackend.Units.Skills.Skill
  alias GameBackend.Units.Skills.Mechanic
  alias GameBackend.Units.Skills.Mechanics.Effect
  alias GameBackend.Units.Unit

  require Logger

  @default_seed 1
  @default_maximum_steps 24_000
  @ultimate_energy_cost 500
  @miliseconds_per_step 50

  @doc """
  Runs a battle between two teams.
  Teams are expected to be lists of units with their character and their skills preloaded.
  Optionally, they can come together in a tuple with a list of initial modifiers that might affect them.
  Either all of them are affected by initial modifiers (modifiers list can be empty, but the tuple format must be followed), or none are.

  Returns a map with the the initial state of the battle, the development of the battle for animation, and the result of the battle.

  Options allowed are:

  - `maximum_steps`
  - `seed`

  ## Examples

      iex> team_1 = Enum.map(user1.units, GameBackend.Repo.preload([character: [:basic_skill, :ultimate_skill]]))
      iex> team_2 = Enum.map(user2.units, GameBackend.Repo.preload([character: [:basic_skill, :ultimate_skill]]))
      iex> run_battle(team_1, team_2)
      %{initial_state: %{}, steps: [%{actions: [], step_number: 1}, ...], result: :team_1}
  """
  def run_battle(team_1, team_2, options \\ [])

  def run_battle([{_unit, _initial_modifiers} | _] = team_1, team_2, options) do
    team_1_with_level_cap_and_modifiers =
      Enum.map(team_1, fn {unit, modifiers} ->
        case Map.get(modifiers, {"max_level", "Add"}, 0) do
          0 ->
            {unit, Map.drop(modifiers, [{"max_level", "Add"}])}

          max_level ->
            {%Unit{unit | level: min(unit.level, round(max_level))}, Map.drop(modifiers, [{"max_level", "Add"}])}
        end
      end)

    team_1_before_modifiers =
      Enum.map(team_1_with_level_cap_and_modifiers, fn {unit, modifiers} ->
        {create_unit_map(unit, 1), modifiers}
      end)

    new_team_1 =
      Enum.into(team_1_before_modifiers, %{}, fn {{id, unit}, modifiers} ->
        unit_after_additive_modifiers =
          modifiers
          |> Enum.filter(fn {{_attribute, operation}, _value} ->
            operation == "Add"
          end)
          |> Enum.reduce(unit, fn {{attribute, _operation}, value}, unit_acc ->
            if attribute == "health" do
              # We update both :health and :max_health
              unit_acc
              |> Map.update(:health, value, &(&1 + value))
              |> Map.update(:max_health, value, &(&1 + value))
            else
              Map.update(unit_acc, string_to_atom(attribute), value, &(&1 + value))
            end
          end)

        unit_after_multiplicative_modifiers =
          modifiers
          |> Enum.filter(fn {{_attribute, operation}, _value} ->
            operation == "Multiply"
          end)
          |> Enum.reduce(unit_after_additive_modifiers, fn {{attribute, _operation}, value}, unit_acc ->
            if attribute == "health" do
              # We update both :health and :max_health
              unit_acc
              |> Map.update(
                :health,
                value,
                &(value |> Decimal.from_float() |> Decimal.mult(&1) |> Decimal.round() |> Decimal.to_integer())
              )
              |> Map.update(
                :max_health,
                value,
                &(value |> Decimal.from_float() |> Decimal.mult(&1) |> Decimal.round() |> Decimal.to_integer())
              )
            else
              Map.update(
                unit_acc,
                string_to_atom(attribute),
                value,
                &(value |> Decimal.from_float() |> Decimal.mult(&1) |> Decimal.round() |> Decimal.to_integer())
              )
            end
          end)

        {id, unit_after_multiplicative_modifiers}
      end)

    team_2 = Enum.into(team_2, %{}, fn unit -> create_unit_map(unit, 2) end)

    simulate_battle(new_team_1, team_2, options)
  end

  def run_battle(team_1, team_2, options) do
    team_1 = Enum.into(team_1, %{}, fn unit -> create_unit_map(unit, 1) end)
    team_2 = Enum.into(team_2, %{}, fn unit -> create_unit_map(unit, 2) end)

    simulate_battle(team_1, team_2, options)
  end

  defp simulate_battle(team_1, team_2, options) do
    maximum_steps = options[:maximum_steps] || @default_maximum_steps
    seed = options[:seed] || @default_seed

    :rand.seed(:default, seed)
    Logger.info("Running battle with seed: #{seed}")

    initial_state = %{units: Map.merge(team_1, team_2), skills_being_cast: [], pending_effects: []}

    # The initial_step_state is what allows the battle to be simultaneous. If we refreshed the accum on every action,
    # we would be left with a turn-based battle. Instead we take decisions based on the state of the battle at the beggining
    # of the step regardless of the changes that happened "before" (execution-wise) in this step.

    {history, result} =
      Enum.reduce_while(
        0..(maximum_steps - 1),
        {initial_state, []},
        fn step, {initial_step_state, history} ->
          {new_state, new_history} =
            {Map.put(initial_step_state, :step_number, step), history}
            |> advance_history_step()
            |> process_step_for_units()
            |> process_step_for_skills(initial_step_state)
            |> process_step_for_effects()
            |> cap_units_energy()
            |> cap_units_health()

          Logger.info("Step #{step} finished: #{inspect(format_step_state(new_state))}")

          {new_state, new_history}
          |> remove_dead_units()
          |> check_winner(step, maximum_steps)
        end
      )

    %{initial_state: transform_initial_state_for_replay(initial_state), steps: Enum.reverse(history), result: result}
  end

  # Removes dead units from the battle state.
  defp remove_dead_units({state, history}) do
    {new_units, new_history} =
      Enum.reduce(state.units, {%{}, history}, fn {unit_id, unit}, {units, history_acc} ->
        if unit.health > 0 do
          {Map.put(units, unit_id, unit), history_acc}
        else
          Logger.info("Unit #{format_unit_name(unit)} died.")

          new_history = add_to_history(history_acc, %{unit_id: unit_id}, :death)

          {units, new_history}
        end
      end)

    {Map.put(state, :units, new_units), new_history}
  end

  defp advance_history_step({state, []}) do
    {state, [%{step_number: 0, actions: []}]}
  end

  defp advance_history_step({state, [%{step_number: step_number} | _tail] = history}) do
    {state, [%{step_number: step_number + 1, actions: []} | history]}
  end

  # Check if the battle has ended.
  # Battle can end if all unit of a team are dead, or if the maximum step amount has been reached.
  defp check_winner({state, history}, step, maximum_steps) do
    winner =
      cond do
        Enum.empty?(state.units) -> "tie"
        Enum.all?(state.units, fn {_id, unit} -> unit.team == 2 end) -> "team_2"
        Enum.all?(state.units, fn {_id, unit} -> unit.team == 1 end) -> "team_1"
        true -> "none"
      end

    case winner do
      "none" ->
        if step == maximum_steps - 1 do
          Logger.info("Battle timeout.")
          {:halt, {history, "timeout"}}
        else
          {:cont, {state, history}}
        end

      result ->
        Logger.info("Battle ended. Result: #{result}.")

        {:halt, {history, result}}
    end
  end

  defp process_step_for_units({initial_step_state, history}) do
    Enum.reduce(initial_step_state.units, {initial_step_state, history}, fn {unit_id, unit}, {current_state, history} ->
      Logger.info("Process step #{initial_step_state.step_number} for unit #{format_unit_name(unit)}")
      process_step_for_unit(initial_step_state.units[unit_id], current_state, initial_step_state, history)
    end)
  end

  # Calculate the new state of the battle after a step passes for a unit.
  # Updates cooldowns, casts skills and reduces self-affecting modifier durations.
  defp process_step_for_unit(unit, current_state, initial_step_state, history) do
    current_state = Map.put(current_state, :units, Map.put(current_state.units, unit.id, unit))

    {new_state, new_history} =
      cond do
        not can_attack(unit, initial_step_state) ->
          {current_state, history}

        can_cast_ultimate_skill(unit) ->
          Logger.info("Unit #{format_unit_name(unit)} casting Ultimate skill")

          new_state =
            current_state
            |> Map.put(:skills_being_cast, [unit.ultimate_skill | current_state.skills_being_cast])
            |> put_in([:units, unit.id, :energy], 0)

          new_history =
            add_to_history(
              history,
              %{
                caster_id: unit.id,
                target_ids: [],
                skill_id: unit.ultimate_skill.id,
                skill_action_type: :ANIMATION_START,
                stats_affected: []
              },
              :skill_action
            )
            |> add_to_history(
              %{
                target_id: unit.id,
                stat_affected: %{
                  stat: :ENERGY,
                  amount: 0
                }
              },
              :stat_override
            )

          {new_state, new_history}

        can_cast_basic_skill(unit) ->
          Logger.info("Unit #{format_unit_name(unit)} casting basic skill")

          new_state =
            current_state
            |> Map.put(:skills_being_cast, [unit.basic_skill | current_state.skills_being_cast])
            |> put_in(
              [:units, unit.id, :basic_skill, :remaining_cooldown],
              # We need this + 1 because we're going to reduce the cooldown at the end of the step
              calculate_cooldown(unit.basic_skill, unit) + 1
            )
            |> update_in([:units, unit.id, :energy], &(&1 + unit.basic_skill.energy_regen))

          new_history =
            add_to_history(
              history,
              %{
                caster_id: unit.id,
                target_ids: [],
                skill_id: unit.basic_skill.id,
                skill_action_type: :ANIMATION_START,
                stats_affected: []
              },
              :skill_action
            )
            |> add_to_history(
              %{
                target_id: unit.id,
                skill_id: unit.basic_skill.id,
                amount: unit.basic_skill.energy_regen
              },
              :energy_regen
            )

          {new_state, new_history}

        true ->
          {current_state, history}
      end

    # Reduce modifier remaining timers & remove expired ones
    {additives, new_history} = reduce_modifier_timers(unit.modifiers.additives, unit, new_history)
    {multiplicatives, new_history} = reduce_modifier_timers(unit.modifiers.multiplicatives, unit, new_history)
    {overrides, new_history} = reduce_modifier_timers(unit.modifiers.overrides, unit, new_history)

    new_modifiers =
      %{
        additives: additives,
        multiplicatives: multiplicatives,
        overrides: overrides
      }

    # Reduce tags remaining timers & remove expired ones
    {new_tags, new_history} = reduce_tag_timers(unit, new_history)

    # Reduce basic skill cooldown
    new_state =
      new_state
      |> put_in(
        [:units, unit.id, :basic_skill, :remaining_cooldown],
        max(new_state.units[unit.id].basic_skill.remaining_cooldown - 1, 0)
      )
      |> put_in([:units, unit.id, :modifiers], new_modifiers)
      |> put_in([:units, unit.id, :tags], new_tags)

    {new_unit, new_history} = process_executions_over_time(unit, new_state.units[unit.id], new_history)

    new_state = put_in(new_state, [:units, unit.id], new_unit)

    {new_state, new_history}
  end

  defp calculate_cooldown(skill, unit) do
    speed = calculate_unit_stat(unit, :speed) |> Decimal.from_float()

    divisor = Decimal.div(Decimal.max(-99, speed), 100) |> Decimal.add(1)

    Decimal.div(skill.base_cooldown, divisor)
    |> Decimal.round()
    |> Decimal.to_integer()
  end

  # Reduces modifier timers and removes expired ones.
  # Called when processing a step for a unit.
  defp reduce_modifier_timers(modifiers, unit, history) do
    Enum.reduce(modifiers, {[], history}, fn modifier, {acc, history_acc} ->
      case modifier.remaining_steps do
        # Modifier is permanent
        -1 ->
          {[modifier | acc], history_acc}

        # Modifier expired
        0 ->
          Logger.info("Modifier [#{format_modifier_name(modifier)}] expired for #{format_unit_name(unit)}.")

          {acc,
           add_to_history(
             history_acc,
             %{
               skill_id: modifier.skill_id,
               target_id: unit.id,
               stat_affected: %{
                 stat: modifier.attribute |> String.upcase() |> string_to_atom(),
                 amount: modifier.magnitude
               },
               operation: modifier.operation
             },
             :modifier_expired
           )}

        # Modifier still going, reduce its timer by one
        remaining ->
          Logger.info(
            "Modifier [#{format_modifier_name(modifier)}] remaining time reduced for #{format_unit_name(unit)} to #{remaining - 1}."
          )

          {[Map.put(modifier, :remaining_steps, remaining - 1) | acc], history_acc}
      end
    end)
  end

  # Reduces tag timers and removes expired ones.
  # Called when processing a step for a unit.
  defp reduce_tag_timers(unit, history) do
    Enum.reduce(unit.tags, {[], history}, fn tag, {acc, history} ->
      case tag.remaining_steps do
        # Tag is permanent
        -1 ->
          {[tag | acc], history}

        # Tag expired
        0 ->
          Logger.info(~c"Tag \"#{tag.tag}\" expired for #{format_unit_name(unit)}.")

          {acc,
           add_to_history(
             history,
             %{
               skill_id: tag.skill_id,
               target_id: unit.id,
               tag: tag.tag
             },
             :tag_expired
           )}

        # Tag still going, reduce its timer by one
        remaining ->
          Logger.info(~c"Tag \"#{tag.tag}\" remaining time reduced for #{format_unit_name(unit)} to #{remaining - 1}.")

          {[Map.put(tag, :remaining_steps, remaining - 1) | acc], history}
      end
    end)
  end

  defp process_step_for_skills({current_state, history}, initial_step_state) do
    Enum.reduce(current_state.skills_being_cast, {current_state, history}, fn skill, {current_state, history_acc} ->
      Logger.info(
        "Process step #{current_state.step_number} for skill #{skill.name} cast by #{String.slice(skill.caster_id, 0..2)}"
      )

      # We need the initial_step_state to decide effect targets
      process_step_for_skill(skill, current_state, initial_step_state, history_acc)
    end)
  end

  # Calculate the new state of the battle after a step passes for a skill being cast.
  # Reduces the remaining animation and effect trigger, and casts the effects if the latter has ended.
  defp process_step_for_skill(skill, current_state, initial_step_state, history) do
    # Check the casting unit is alive
    if Map.has_key?(current_state.units, skill.caster_id) do
      # Process step for all mechanics
      {{new_mechanics, new_state}, new_history} =
        Enum.reduce(
          skill.mechanics,
          {{[], current_state}, history},
          fn mechanic, {{mechanics_acc, state_acc}, history_acc} ->
            {{new_mechanic, new_state}, new_history} =
              process_mechanic_trigger_delay(mechanic, state_acc, initial_step_state, history_acc)

            {{[new_mechanic | mechanics_acc], new_state}, new_history}
          end
        )

      if skill.animation_duration == 0 do
        # If the animation has finished, we remove skill from list.
        {Map.put(new_state, :skills_being_cast, List.delete(new_state.skills_being_cast, skill)), new_history}
      else
        # Otherwise, we update it with its new state.
        new_skill = %{skill | animation_duration: skill.animation_duration - 1, mechanics: new_mechanics}

        {Map.put(new_state, :skills_being_cast, [new_skill | List.delete(new_state.skills_being_cast, skill)]),
         new_history}
      end
    else
      # If the unit died, just delete the skill being cast
      Logger.info("Skill caster #{String.slice(skill.caster_id, 0..2)} died. Deleting skill from list.")
      {Map.put(current_state, :skills_being_cast, List.delete(current_state.skills_being_cast, skill)), history}
    end
  end

  # Calculate the new state of the battle after a step passes for a mechanic.
  # If the trigger_delay is ready, process the mechanic.
  defp process_mechanic_trigger_delay(
         %{trigger_delay: 0} = mechanic,
         current_state,
         initial_step_state,
         history
       ) do
    Logger.info("Trigger delay for mechanic #{String.slice(mechanic.id, 0..2)} of skill #{mechanic.skill_id} ready.")
    process_mechanic(mechanic, current_state, initial_step_state, history)
  end

  # If the effects have already triggered, do nothing.
  defp process_mechanic_trigger_delay(
         %{trigger_delay: -1} = mechanic,
         current_state,
         _initial_step_state,
         history
       ),
       do: {{mechanic, current_state}, history}

  # If the effect hasn't triggered yet, reduce the remaining trigger_delay counter.
  defp process_mechanic_trigger_delay(mechanic, current_state, _initial_step_state, history) do
    {{%{mechanic | trigger_delay: mechanic.trigger_delay - 1}, current_state}, history}
  end

  # Process an ApplyEffectsTo mechanic, adding the mechanic's effects to the pending_effects list.
  defp process_mechanic(%{apply_effects_to: apply_effects_to} = mechanic, current_state, initial_step_state, history)
       when not is_nil(apply_effects_to) do
    caster = current_state.units[mechanic.caster_id]
    # "Queues" the effect to be processed when its delay reaches 0.
    # We store the caster's state in the effect in case the unit dies before the effect's delay ends.
    # Also, we want to calculate numbers like damage done based on the status of the caster when the effect was cast.

    targets = choose_targets(caster, apply_effects_to.targeting_strategy, initial_step_state)

    {effects_with_caster, new_history} =
      Enum.reduce(apply_effects_to.effects, {[], history}, fn effect, {effects_list, history} ->
        new_effect =
          effect
          |> Map.put(:caster, caster)
          |> Map.put(:targets, targets)
          |> Map.put(:skill_id, mechanic.skill_id)

        new_history =
          add_to_history(
            history,
            %{
              caster_id: caster.id,
              target_ids: new_effect.targets,
              skill_id: mechanic.skill_id,
              skill_action_type: :EFFECT_TRIGGER,
              stats_affected: []
            },
            :skill_action
          )

        {[new_effect | effects_list], new_history}
      end)

    new_state = Map.put(current_state, :pending_effects, effects_with_caster ++ current_state.pending_effects)

    {{%{mechanic | trigger_delay: -1}, new_state}, new_history}
  end

  # Calculate the new state of the battle after a step passes for all pending effects
  def process_step_for_effects({state, history}) do
    {{updated_pending_effects, updated_game_state}, new_history} =
      Enum.reduce(state.pending_effects, {{[], state}, history}, fn effect,
                                                                    {{new_pending_effects, current_state}, new_history} ->
        # Calculate the new state of the battle after a step passes for a pending effect.
        case effect do
          %{delay: 0} ->
            # If the effect is ready to be processed, we apply it.
            Logger.info("#{format_unit_name(effect.caster)}'s effect is ready to be processed")

            {targets_after_effect, new_history} =
              Enum.reduce(effect.targets, {%{}, new_history}, fn target_id, {new_targets, history_acc} ->
                target = Map.get(current_state.units, target_id, target_id)

                {new_target, new_history} =
                  maybe_apply_effect(
                    effect,
                    target,
                    effect.caster,
                    current_state.step_number,
                    effect_hits?(effect, target),
                    history_acc
                  )

                {maybe_put_new_target(new_targets, new_target), new_history}
              end)

            new_state = update_in(current_state, [:units], fn units -> Map.merge(units, targets_after_effect) end)

            # We don't add this effect to the new_pending_effects list because it has already been applied
            {{new_pending_effects, new_state}, new_history}

          effect ->
            # If the effect isn't ready to be processed, we reduce its remaining delay.
            {{[%{effect | delay: effect.delay - 1} | new_pending_effects], current_state}, new_history}
        end
      end)

    {Map.put(updated_game_state, :pending_effects, updated_pending_effects), new_history}
  end

  defp maybe_put_new_target(targets, nil), do: targets
  defp maybe_put_new_target(targets, target), do: Map.put(targets, target.id, target)

  # Check if the unit can attack this turn.
  # For now, attacking capability is only affected by whether the unit is currently casting a skill.
  # Later on, things like stuns will be handled here.
  defp can_attack(unit, initial_step_state) do
    # Check the unit is not casting anything right now and is not stunned
    cond do
      Enum.any?(initial_step_state.skills_being_cast, &(&1.caster_id == unit.id)) ->
        Logger.info("Unit #{format_unit_name(unit)} cannot attack because it is casting another skill")
        false

      Enum.any?(unit.tags, &(&1.tag == "ControlEffect.Stun")) ->
        Logger.info("Unit #{format_unit_name(unit)} cannot attack because it is stunned")
        false

      true ->
        true
    end
  end

  # Check if the unit can cast their ultimate skill this step.
  defp can_cast_ultimate_skill(unit) do
    cond do
      unit.energy < @ultimate_energy_cost ->
        false

      Enum.any?(unit.tags, fn %{tag: tag} -> tag == "ControlEffect.Silence" end) ->
        Logger.info("Unit #{format_unit_name(unit)} cannot cast its ultimate skill because it is silenced.")
        false

      true ->
        true
    end
  end

  # Check if the unit can cast their basic skill this step.
  defp can_cast_basic_skill(unit), do: unit.basic_skill.remaining_cooldown <= 0

  defp choose_targets(caster, targeting_strategy, state) do
    targeteable_units =
      state.units
      |> Enum.filter(fn {_, unit} -> not Enum.any?(unit.tags, &(&1.tag == "Untargetable")) end)

    state_with_targeteable_units =
      Map.put(state, :units, targeteable_units)

    choose_targets_by_strategy(caster, targeting_strategy, state_with_targeteable_units)
  end

  # Choose the targets for an effect with "random" as the strategy. Returns the target ids.
  # The `== target_allies` works as a negation operation when `target_allies` is `false`, and does nothing when `true`.
  defp choose_targets_by_strategy(caster, %{type: "random"} = targeting_strategy, state),
    do:
      state.units
      |> Enum.filter(fn {_id, unit} -> unit.team == caster.team == targeting_strategy.target_allies end)
      |> Enum.take_random(targeting_strategy.count)
      |> Enum.map(fn {id, _unit} -> id end)

  defp choose_targets_by_strategy(caster, %{type: "nearest"} = targeting_strategy, state) do
    config_name = if targeting_strategy.target_allies, do: :ally_proximities, else: :enemy_proximities

    state.units
    |> Enum.map(fn {_id, unit} -> unit end)
    |> Enum.filter(fn unit -> unit.team == caster.team == targeting_strategy.target_allies and unit.id != caster.id end)
    |> find_by_proximity(
      Application.get_env(:champions, :"slot_#{caster.slot}_proximities")[config_name],
      targeting_strategy.count
    )
    |> Enum.map(& &1.id)
  end

  defp choose_targets_by_strategy(caster, %{type: "furthest"} = targeting_strategy, state) do
    config_name = if targeting_strategy.target_allies, do: :ally_proximities, else: :enemy_proximities

    state.units
    |> Enum.map(fn {_id, unit} -> unit end)
    |> Enum.filter(fn unit -> unit.team == caster.team == targeting_strategy.target_allies and unit.id != caster.id end)
    |> find_by_proximity(
      Application.get_env(:champions, :"slot_#{caster.slot}_proximities")[config_name] |> Enum.reverse(),
      targeting_strategy.count
    )
    |> Enum.map(& &1.id)
  end

  defp choose_targets_by_strategy(caster, %{type: "backline"} = targeting_strategy, state) do
    target_team =
      Enum.filter(state.units, fn {_id, unit} -> unit.team == caster.team == targeting_strategy.target_allies end)

    take_unit_ids_by_slots(target_team, [3, 4, 5, 6])
  end

  defp choose_targets_by_strategy(caster, %{type: "frontline"} = targeting_strategy, state) do
    target_team =
      Enum.filter(state.units, fn {_id, unit} -> unit.team == caster.team == targeting_strategy.target_allies end)

    take_unit_ids_by_slots(target_team, [1, 2])
  end

  defp choose_targets_by_strategy(caster, %{type: "self"}, _state) do
    [caster.id]
  end

  defp choose_targets_by_strategy(caster, %{type: %{"lowest" => stat}} = targeting_strategy, state) do
    choose_units_by_stat_and_team(
      state.units,
      stat,
      targeting_strategy.count,
      caster,
      targeting_strategy.target_allies,
      :desc
    )
  end

  defp choose_targets_by_strategy(caster, %{type: %{"highest" => stat}} = targeting_strategy, state) do
    choose_units_by_stat_and_team(
      state.units,
      stat,
      targeting_strategy.count,
      caster,
      targeting_strategy.target_allies,
      :asc
    )
  end

  defp choose_targets_by_strategy(caster, %{type: "all"} = targeting_strategy, state),
    do:
      state.units
      |> Enum.filter(fn {_id, unit} -> unit.team == caster.team == targeting_strategy.target_allies end)
      |> Enum.map(fn {id, _unit} -> id end)

  defp find_by_proximity(units, slots_priorities, amount) do
    sorted_units =
      Enum.sort_by(units, fn unit ->
        Enum.find_index(slots_priorities, &(&1 == unit.slot))
      end)

    Enum.take(sorted_units, amount)
  end

  defp choose_units_by_stat_and_team(units, stat, count, caster, target_allies, order) do
    target_team =
      Enum.filter(units, fn {_id, unit} -> unit.team == caster.team == target_allies end)

    Enum.map(target_team, fn {_id, unit} -> unit end)
    |> sort_units_by_stat(stat, order)
    |> Enum.take(count)
    |> Enum.map(fn unit -> unit.id end)
  end

  defp take_unit_ids_by_slots(units, slots) do
    slots_units = Enum.filter(units, fn {_id, unit} -> unit.slot in slots end)

    # Fallback to all remaining units if there are no units in slots
    # Might need to change this if we use this function for more than Frontline-Backline targeting
    units =
      case slots_units do
        [] ->
          units

        _ ->
          slots_units
      end

    Enum.map(units, fn {id, _unit} -> id end)
  end

  # If we receive the target's id, it means that the unit has died before the effect hits.
  # We send it as an EFFECT_MISS action.
  defp maybe_apply_effect(effect, id, caster, _current_step_number, _hits, history) when is_binary(id) do
    new_history =
      add_to_history(
        history,
        %{
          caster_id: caster.id,
          target_ids: [id],
          skill_id: effect.skill_id,
          skill_action_type: :EFFECT_MISS
        },
        :skill_action
      )

    {nil, new_history}
  end

  # Apply an effect to its target. Returns the new state of the target.
  # For now this applies the executions on the spot.
  # Returns the new state of the target.
  defp maybe_apply_effect(effect, target, caster, current_step_number, true, history) do
    new_history =
      add_to_history(
        history,
        %{
          caster_id: caster.id,
          target_ids: [target.id],
          skill_id: effect.skill_id,
          skill_action_type: :EFFECT_HIT
        },
        :skill_action
      )

    {target_after_modifiers, new_history} =
      Enum.reduce(effect.modifiers, {target, new_history}, fn modifier, {target, history_acc} ->
        # If it's permanent, we set its duration to -1
        new_modifier =
          modifier
          |> Map.put(:remaining_steps, get_duration(effect.type))
          |> Map.put(:step_applied_at, current_step_number)

        Logger.info("Applying modifier [#{format_modifier_name(new_modifier)}] to #{format_unit_name(target)}.")

        new_history =
          add_to_history(
            history_acc,
            %{
              skill_id: modifier.skill_id,
              target_id: target.id,
              stat_affected: %{
                stat: modifier.attribute |> String.upcase() |> string_to_atom(),
                amount: modifier.magnitude
              },
              operation: modifier.operation
            },
            :modifier_received
          )

        new_target =
          case modifier.operation do
            "Add" ->
              put_in(target, [:modifiers, :additives], [new_modifier | target.modifiers.additives])

            "Multiply" ->
              put_in(target, [:modifiers, :multiplicatives], [new_modifier | target.modifiers.multiplicatives])

            "Override" ->
              put_in(target, [:modifiers, :overrides], [new_modifier | target.modifiers.overrides])
          end

        {new_target, new_history}
      end)

    {target_after_tags, new_history} =
      Enum.reduce(effect.components, {target_after_modifiers, new_history}, fn component, {target, history} ->
        if component["type"] == "ApplyTags",
          do: apply_tags(target, component["tags"], effect, history),
          else: {target, history}
      end)

    {target_after_executions, new_history} =
      Enum.reduce(effect.executions, {target_after_tags, new_history}, fn execution, {target_acc, history_acc} ->
        process_execution(execution, target_acc, caster, history_acc, effect.skill_id)
      end)

    Enum.reduce(effect.executions_over_time, {target_after_executions, new_history}, fn execution_over_time,
                                                                                        {target_acc, _history_acc} ->
      update_in(target_acc, [:executions_over_time], fn current_executions ->
        [
          %{
            execution: execution_over_time,
            caster: caster,
            skill_id: effect.skill_id,
            remaining_duration: get_duration(effect.type),
            remaining_interval_steps: get_interval_steps(execution_over_time)
          }
          | current_executions
        ]
      end)
      |> apply_tags(execution_over_time["apply_tags"], effect, new_history)
    end)
  end

  defp maybe_apply_effect(effect, target, caster, _current_step_number, false, history) do
    Logger.info("#{format_unit_name(effect.caster)}'s effect missed.")

    new_history =
      add_to_history(
        history,
        %{
          caster_id: caster.id,
          target_ids: [target.id],
          skill_id: effect.skill_id,
          skill_action_type: :EFFECT_MISS
        },
        :skill_action
      )

    {target, new_history}
  end

  # We substract a step because the modifier/tag is removed on the step when its' *initial* remaining value is 0.
  # For a 2-step duration, this looks like:
  # Step 0: Applied. steps_remaining = 2-1 = 1. Will be effective starting next step.
  # Step 1: steps_remaining = 1. Modifier is effective. steps_remaining != 0 so we substract 1. Next steps_remaining = 1-1 = 0.
  # Step 2: steps_remaining = 0. Modifier is effective. steps_remaining == 0 so we remove it from the modifiers list for next step.
  # Step 3: Modifier has been removed, and is no longer effective.
  defp get_duration(%{duration: duration}), do: duration - 1

  # If the effect type doesn't have a duration, then we assume it is permanent.
  defp get_duration(_type), do: -1

  defp get_interval_steps(execution_over_time) do
    # Decrement in 1 because we're already processing the execution in the next step
    execution_over_time["interval"] - 1
  end

  # Return whether an effect hits.
  defp effect_hits?(effect, target_id) when is_binary(target_id), do: !chance_to_apply_hits?(effect)

  defp effect_hits?(effect, target) do
    cond do
      !target_tag_requirements_met?(effect, target) -> false
      !chance_to_apply_hits?(effect) -> false
      true -> true
    end
  end

  defp target_tag_requirements_met?(effect, target) do
    requirements_component =
      Enum.find(effect.components, fn comp -> comp["type"] == "TargetTagRequirements" end)

    case requirements_component do
      nil ->
        true

      requirements_component ->
        target_tags = Enum.map(target.tags, fn %{tag: tag} -> tag end)
        Enum.all?(requirements_component["tags"], &(&1 in target_tags))
    end
  end

  defp chance_to_apply_hits?(effect) do
    chance_to_apply_component =
      Enum.find(effect.components, fn comp -> comp["type"] == "ChanceToApply" end)

    case chance_to_apply_component do
      nil ->
        true

      chance_to_apply_component ->
        chance_to_apply_component["chance"] >= :rand.uniform()
    end
  end

  defp apply_tags(target, tags_to_apply, effect, history) do
    steps = get_duration(effect.type)

    {new_tags, new_history} =
      Enum.reduce(tags_to_apply || [], {[], history}, fn tag, {acc, history} ->
        Logger.info(~c"Applying tag \"#{tag}\" to unit #{format_unit_name(target)} for #{steps} steps.")

        new_history =
          add_to_history(
            history,
            %{
              skill_id: effect.skill_id,
              target_id: target.id,
              tag: tag
            },
            :tag_received
          )

        {[%{tag: tag, remaining_steps: steps, skill_id: effect.skill_id} | acc], new_history}
      end)

    new_target =
      update_in(target, [:tags], fn tags ->
        tags ++ new_tags
      end)

    {new_target, new_history}
  end

  # Apply a DealDamage execution to its target. Returns the new state of the target.
  defp process_execution(
         %{
           "type" => "DealDamage",
           "attack_ratio" => attack_ratio,
           "energy_recharge" => energy_recharge
         },
         target,
         caster,
         history,
         skill_id
       ) do
    damage_after_defense = calculate_damage(caster, target, attack_ratio)

    Logger.info(
      "#{format_unit_name(caster)} dealing #{damage_after_defense} damage to #{format_unit_name(target)} (#{target.health} -> #{target.health - damage_after_defense}). Target energy recharge: #{energy_recharge}."
    )

    new_history =
      add_to_history(
        history,
        %{
          target_id: target.id,
          skill_id: skill_id,
          stat_affected: %{stat: :HEALTH, amount: -damage_after_defense}
        },
        :execution_received
      )
      |> add_to_history(
        %{
          target_id: target.id,
          skill_id: skill_id,
          amount: energy_recharge
        },
        :energy_regen
      )

    new_target =
      target
      |> Map.put(:health, target.health - damage_after_defense)
      |> Map.put(:energy, min(target.energy + energy_recharge, @ultimate_energy_cost))

    {new_target, new_history}
  end

  # Apply a Heal execution to its target. Returns the new state of the target.
  defp process_execution(
         %{
           "type" => "Heal",
           "attack_ratio" => attack_ratio
         },
         target,
         caster,
         history,
         skill_id
       ) do
    heal_amount = max(floor(attack_ratio * calculate_unit_stat(caster, :attack)), 0)

    Logger.info(
      "#{format_unit_name(caster)} healing #{heal_amount} HP to #{format_unit_name(target)} (#{target.health} -> #{target.health + heal_amount})"
    )

    new_history =
      add_to_history(
        history,
        %{
          target_id: target.id,
          skill_id: skill_id,
          stat_affected: %{stat: :HEALTH, amount: heal_amount}
        },
        :execution_received
      )

    new_target = Map.put(target, :health, target.health + heal_amount)

    # We don't cap to max_health here because the unit's health at the end of the step would depend
    # on the order in which we process the executions.

    {new_target, new_history}
  end

  # Apply an AddEnergy execution to its target. Returns the new state of the target.
  defp process_execution(
         %{
           "type" => "AddEnergy",
           "amount" => amount
         },
         target,
         caster,
         history,
         skill_id
       ) do
    Logger.info(
      "#{format_unit_name(caster)} adding #{amount} energy to #{format_unit_name(target)} (#{target.energy} -> #{target.energy + amount})"
    )

    new_history =
      add_to_history(
        history,
        %{
          target_id: target.id,
          skill_id: skill_id,
          stat_affected: %{stat: :ENERGY, amount: amount}
        },
        :execution_received
      )

    new_target = Map.put(target, :energy, target.energy + amount)

    {new_target, new_history}
  end

  defp process_execution(
         _,
         target,
         caster,
         history,
         _skill_id
       ) do
    Logger.warning("#{format_unit_name(caster)} tried to apply an unknown execution to #{format_unit_name(target)}")
    {target, history}
  end

  defp process_executions_over_time(unit_initial_state, current_unit, history) do
    Enum.reduce(unit_initial_state.executions_over_time, {current_unit, history}, fn execution_over_time,
                                                                                     {unit_acc, history_acc} ->
      process_execution_over_time(execution_over_time, unit_acc, history_acc, unit_initial_state)
    end)
  end

  defp process_execution_over_time(
         %{remaining_duration: -1} = execution_over_time,
         target,
         history,
         _target_initial_state
       ) do
    # If the execution is over, we remove it from the target
    new_target =
      update_in(target, [:executions_over_time], fn current_executions ->
        Enum.filter(current_executions, fn exec -> exec != execution_over_time end)
      end)

    {new_target, history}
  end

  defp process_execution_over_time(
         %{execution: %{"type" => "DealDamageOverTime"}, remaining_interval_steps: remaining_interval_steps} =
           execution_over_time,
         target,
         history,
         target_initial_state
       ) do
    if remaining_interval_steps == 0 do
      apply_deal_damage_over_time(
        execution_over_time,
        target,
        history,
        target_initial_state
      )
    else
      execution = target.executions_over_time |> Enum.find(fn exec -> exec == execution_over_time end)

      new_execution_over_time =
        Map.put(execution_over_time, :remaining_interval_steps, execution.remaining_interval_steps - 1)

      new_target =
        update_in(target, [:executions_over_time], fn current_executions ->
          Enum.filter(current_executions, fn exec -> exec != execution end) ++ [new_execution_over_time]
        end)

      Logger.info("Remaining period: #{new_execution_over_time.remaining_interval_steps}")

      {new_target, history}
    end
  end

  defp process_execution_over_time(
         execution_over_time,
         target,
         history,
         _target_initial_state
       ) do
    Logger.warning(
      "#{format_unit_name(execution_over_time.caster)} tried to apply an unknown execution over time to #{format_unit_name(target)}"
    )

    {target, history}
  end

  defp apply_deal_damage_over_time(execution_over_time, target, history, target_initial_state) do
    damage_after_defense =
      calculate_damage(execution_over_time.caster, target_initial_state, execution_over_time.execution["attack_ratio"])

    Logger.info(
      "#{format_unit_name(execution_over_time.caster)} dealing #{damage_after_defense} damage to #{format_unit_name(target)} (#{target.health} -> #{target.health - damage_after_defense}). Steps remaining: #{execution_over_time.remaining_duration}."
    )

    new_history =
      add_to_history(
        history,
        %{
          target_id: target.id,
          skill_id: execution_over_time.skill_id,
          stat_affected: %{stat: :HEALTH, amount: -damage_after_defense}
        },
        :execution_received
      )

    initial_interval_steps = get_interval_steps(execution_over_time.execution)

    new_target =
      target
      |> Map.put(:health, target.health - damage_after_defense)
      |> update_in([:executions_over_time], fn current_executions ->
        Enum.map(current_executions, fn exec ->
          if exec == execution_over_time do
            Map.put(exec, :remaining_interval_steps, initial_interval_steps)
            |> Map.put(:remaining_duration, exec.remaining_duration - 1)
          else
            exec
          end
        end)
      end)

    {new_target, new_history}
  end

  # Calculate the current amount of the given attribute that the unit has, based on its modifiers.
  defp calculate_unit_stat(unit, attribute) do
    overrides = Enum.filter(unit.modifiers.overrides, &(&1.attribute == Atom.to_string(attribute)))

    if Enum.empty?(overrides) do
      addition =
        Enum.filter(unit.modifiers.additives, &(&1.attribute == Atom.to_string(attribute)))
        |> Enum.reduce(0, fn mod, acc -> mod.magnitude + acc end)

      multiplication =
        Enum.filter(unit.modifiers.multiplicatives, &(&1.attribute == Atom.to_string(attribute)))
        |> Enum.reduce(1, fn mod, acc -> mod.magnitude * acc end)

      (unit[attribute] + addition) * multiplication
    else
      Enum.min_by(overrides, & &1.step_applied_at).magnitude
    end
  end

  # Called at the end of step processing. Sets unit health to max_health if it's above it.
  defp cap_units_health({state, history}) do
    {new_history, units_state} =
      Enum.reduce(state.units, {history, %{}}, fn {unit_id, unit}, {history_acc, state_acc} ->
        units_state =
          Map.put(state_acc, unit_id, Map.put(unit, :health, min(unit.max_health, unit.health)))

        if unit.health > unit.max_health do
          new_history =
            add_to_history(
              history_acc,
              %{
                target_id: unit.id,
                stat_affected: %{
                  stat: :HEALTH,
                  amount: unit.max_health
                }
              },
              :stat_override
            )

          {new_history, units_state}
        else
          {history_acc, units_state}
        end
      end)

    {Map.put(state, :units, units_state), new_history}
  end

  # Called at the end of step processing. Sets unit energy to the max allowed energy if it's above it.
  defp cap_units_energy({state, history}) do
    {Map.put(
       state,
       :units,
       Enum.map(state.units, fn {unit_id, unit} ->
         {unit_id, Map.put(unit, :energy, min(@ultimate_energy_cost, unit.energy))}
       end)
     ), history}
  end

  # Calculates the damage dealt by an attacker to its target, considering the target's defense.
  # We used this function to determine the damage to be dealt by an execution over time, as well as by a DealDamage execution.
  defp calculate_damage(unit, target, attack_ratio) do
    damage_before_defense = max(floor(attack_ratio * calculate_unit_stat(unit, :attack)), 0)

    # FINAL_DMG = DMG * (100 / (100 + DEFENSE))
    damage_after_defense =
      Decimal.mult(damage_before_defense, Decimal.div(100, 100 + target.defense))
      |> Decimal.round()
      |> Decimal.to_integer()

    damage_after_defense
  end

  # Used to create the initial unit maps to be used during simulation.
  defp create_unit_map(%Unit{character: character} = unit, team),
    do:
      {unit.id,
       %{
         id: unit.id,
         team: team,
         slot: unit.slot,
         character_id: character.id,
         character_name: character.name,
         class: character.class,
         faction: character.faction,
         ultimate_skill: create_skill_map(character.ultimate_skill, unit.id),
         basic_skill: create_skill_map(character.basic_skill, unit.id),
         max_health: Units.get_health(unit),
         health: Units.get_health(unit),
         attack: Units.get_attack(unit),
         defense: Units.get_defense(unit),
         speed: Units.get_speed(unit),
         energy: 0,
         modifiers: %{
           additives: [],
           multiplicatives: [],
           overrides: []
         },
         executions_over_time: [],
         tags: []
       }}

  # Used to create the initial skill maps to be used during simulation.
  defp create_skill_map(%Skill{} = skill, caster_id),
    do: %{
      id: skill.id,
      name: skill.name,
      mechanics: Enum.map(skill.mechanics, &create_mechanics_map(&1, skill.id, caster_id)),
      base_cooldown:
        if skill.cooldown do
          div(skill.cooldown, @miliseconds_per_step)
        end,
      remaining_cooldown:
        if skill.cooldown do
          div(skill.cooldown, @miliseconds_per_step)
        end,
      energy_regen: skill.energy_regen || 0,
      animation_duration: div(skill.animation_duration, @miliseconds_per_step),
      caster_id: caster_id
    }

  @implemented_targeting_strategies [
    "random",
    "nearest",
    "furthest",
    "all",
    "frontline",
    "backline",
    "self",
    "lowest",
    "highest"
  ]

  defp create_mechanics_map(%Mechanic{} = mechanic, skill_id, caster_id) do
    targeting_strategy_type = mechanic.apply_effects_to.targeting_strategy.type

    apply_effects_to = %{
      effects: Enum.map(mechanic.apply_effects_to.effects, &create_effect_map(&1, skill_id)),
      targeting_strategy: %{
        # TODO: replace random for the corresponding target type name (CHoM #325)
        # type: mechanic.apply_effects_to.targeting_strategy.type,
        type:
          cond do
            is_binary(targeting_strategy_type) && targeting_strategy_type in @implemented_targeting_strategies ->
              targeting_strategy_type

            hd(Map.keys(targeting_strategy_type)) in @implemented_targeting_strategies ->
              targeting_strategy_type

            true ->
              "random"
          end,
        count: mechanic.apply_effects_to.targeting_strategy.count || 1,
        target_allies: mechanic.apply_effects_to.targeting_strategy.target_allies || false
      }
    }

    %{
      id: mechanic.id,
      skill_id: skill_id,
      caster_id: caster_id,
      trigger_delay: div(mechanic.trigger_delay, @miliseconds_per_step),
      apply_effects_to: apply_effects_to,
      passive_effects: mechanic.passive_effects
    }
  end

  # Used to create the initial effect maps to be used during simulation.
  defp create_effect_map(%Effect{} = effect, skill_id) do
    %{
      type:
        Enum.into(effect.type, %{}, fn
          {"type", type} -> {:type, string_to_atom(type)}
          {"period", period} -> {:period, div(period, @miliseconds_per_step)}
          {"duration", duration} -> {:duration, div(duration, @miliseconds_per_step)}
        end),
      delay: div(effect.initial_delay, @miliseconds_per_step),
      components: effect.components,
      modifiers: Enum.map(effect.modifiers, &Map.put(&1, :skill_id, skill_id)),
      executions: effect.executions,
      executions_over_time:
        Enum.map(effect.executions_over_time, fn eot ->
          Map.put(eot, "interval", div(eot["interval"], @miliseconds_per_step))
        end),
      skill_id: skill_id
    }
  end

  # Format step state for logs.
  defp format_step_state(%{
         units: units,
         skills_being_cast: skl,
         pending_effects: eff
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
            caster_id: &1.caster_id
          }
        ),
      pending_effects: eff
    }
  end

  # Format unit name for logs.
  defp format_unit_name(unit), do: "#{unit.character_name}-#{String.slice(unit.id, 0..2)}"

  # Format modifier name for logs.
  defp format_modifier_name(modifier),
    do: "#{modifier.operation} #{modifier.attribute} by #{modifier.magnitude}"

  defp add_to_history([%{step_number: step_number, actions: actions} | history], entry_to_add, type) do
    [%{step_number: step_number, actions: [%{action_type: {type, entry_to_add}} | actions]} | history]
  end

  defp transform_initial_state_for_replay(%{units: units}) do
    %{
      units:
        Enum.into(units, [], fn {_id, unit} ->
          Map.take(unit, [:id, :health, :slot, :character_id, :team])
        end)
    }
  end

  defp sort_units_by_stat(units, stat, order) do
    Enum.sort(
      units,
      fn unit_1, unit_2 ->
        unit_1_stat = calculate_unit_stat(unit_1, String.to_atom(stat))
        unit_2_stat = calculate_unit_stat(unit_2, String.to_atom(stat))

        decide_order(unit_1_stat, unit_2_stat, order)
      end
    )
  end

  defp decide_order(unit_1_stat, unit_2_stat, :asc) do
    cond do
      unit_1_stat > unit_2_stat -> true
      unit_1_stat == unit_2_stat -> Enum.random([true, false])
      true -> false
    end
  end

  defp decide_order(unit_1_stat, unit_2_stat, :desc) do
    cond do
      unit_1_stat > unit_2_stat -> false
      unit_1_stat == unit_2_stat -> Enum.random([true, false])
      true -> true
    end
  end

  defp string_to_atom("type"), do: :type
  defp string_to_atom("duration"), do: :duration
  defp string_to_atom("period"), do: :period
  defp string_to_atom("instant"), do: :instant
  defp string_to_atom("permanent"), do: :permanent

  defp string_to_atom("attack"), do: :attack
  defp string_to_atom("health"), do: :health
  defp string_to_atom("defense"), do: :defense

  defp string_to_atom("ATTACK"), do: :ATTACK
  defp string_to_atom("DEFENSE"), do: :DEFENSE
  defp string_to_atom("HEALTH"), do: :HEALTH
  defp string_to_atom("ENERGY"), do: :ENERGY
  defp string_to_atom("SPEED"), do: :SPEED
  defp string_to_atom("DAMAGE_REDUCTION"), do: :DAMAGE_REDUCTION
end

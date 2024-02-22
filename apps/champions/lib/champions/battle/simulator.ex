defmodule Champions.Battle.Simulator do
  @moduledoc """
  Runs battles.

  Units have stats that are calculated on battle start (Attack, Max Health, Armor), as well as two skills. The ultimate
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
        |> Enum.take_random(Enum.count(units))
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
          unit
          |> cast_skill(unit.ultimate_skill, initial_step_state, current_state)
          |> put_in([unit.id, :energy], 0)

        can_cast_basic_skill(unit) ->
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
  defp can_cast_ultimate_skill(unit), do: unit.energy >= 500

  # Is cooldown ready?
  defp can_cast_basic_skill(unit), do: unit.basic_skill.remaining_cooldown <= 0

  defp cast_skill(unit, skill, initial_step_state, current_state) do
    target_ids = choose_targets(unit, skill, initial_step_state)

    Enum.reduce(skill.effects, current_state, fn effect, new_state ->
      # If skill doesn't have targeting strategy, we fall back to the effects'
      target_ids =
        if is_nil(target_ids),
          do: choose_targets(unit, effect, initial_step_state),
          else: target_ids

      targets_after_effect =
        Enum.map(target_ids, fn id -> apply_effect(effect, unit, new_state[id]) end)

      Enum.reduce(targets_after_effect, new_state, fn target_unit, acc_state ->
        Map.put(acc_state, target_unit.id, target_unit)
      end)
    end)
  end

  defp choose_targets(_unit, %{targeting_strategy: nil}, _state), do: nil

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
           floor(effect.amount * caster[String.to_atom(stat_based_on)] / 100)

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
      remaining_cooldown: skill.cooldown,
      targeting_strategy: skill.targeting_strategy,
      amount_of_targets: skill.amount_of_targets,
      targets_allies: skill.targets_allies
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

defmodule Arena.Game.Bounties do
  @moduledoc """
  Module to handle quest logic in arena application
  TODO this module shouldn't exist, this a workaround until we have a shared application to
  share business logic between applications without deployed heavy ones
  issue# https://github.com/lambdaclass/mirra_backend/issues/774
  """

  defp parse_comparator("equal"), do: &Kernel.==/2
  defp parse_comparator("distinct"), do: &Kernel.!=/2
  defp parse_comparator("greater"), do: &Kernel.>/2
  defp parse_comparator("greater_or_equal"), do: &Kernel.>=/2
  defp parse_comparator("lesser"), do: &Kernel.</2
  defp parse_comparator("lesser_or_equal"), do: &Kernel.<=/2
  defp parse_comparator(comparator), do: raise("Comparator not implemented yet #{comparator}")

  defp accumulate_objective_progress_by_scope("day", value), do: value
  defp accumulate_objective_progress_by_scope("match", _value), do: 1

  def completed_bounty?(nil, _arena_match_results) do
    false
  end

  def completed_bounty?(quest, arena_match_results) do
    progress =
      arena_match_results
      |> filter_results_that_meet_quest_conditions(quest.conditions)
      |> Enum.reduce(0, fn arena_match_result, acc ->
        type = arena_match_result_field_to_atom(quest.objective.match_tracking_field)
        # We won't accumulate progress if the objective has a wrong field getter
        accumulate_objective_progress_by_scope(quest.objective.scope, Map.get(arena_match_result, type))
        |> case do
          nil ->
            acc

          progress ->
            acc + progress
        end
      end)

    comparator = parse_comparator(quest.objective.comparison)

    comparator.(progress, quest.objective.value)
  end

  defp filter_results_that_meet_quest_conditions(arena_match_results, conditions) do
    Enum.filter(arena_match_results, fn arena_match_result ->
      Enum.all?(conditions, fn condition ->
        type = arena_match_result_field_to_atom(condition.match_tracking_field)

        case Map.get(arena_match_result, type) do
          # We'll result in a false value in case that the quest condition has a wrong field getter
          nil ->
            false

          arena_match_result_value ->
            comparator = parse_comparator(condition.comparison)

            comparator.(arena_match_result_value, condition.value)
        end
      end)
    end)
  end

  defp arena_match_result_field_to_atom("result"), do: :result
  defp arena_match_result_field_to_atom("kills"), do: :kills
  defp arena_match_result_field_to_atom("deaths"), do: :deaths
  defp arena_match_result_field_to_atom("character"), do: :character
  defp arena_match_result_field_to_atom("match_id"), do: :match_id
  defp arena_match_result_field_to_atom("user_id"), do: :user_id
  defp arena_match_result_field_to_atom("position"), do: :position
  defp arena_match_result_field_to_atom("damage_done"), do: :damage_done
  defp arena_match_result_field_to_atom("damage_taken"), do: :damage_taken
  defp arena_match_result_field_to_atom("health_healed"), do: :health_healed
  defp arena_match_result_field_to_atom("killed_by_bot"), do: :killed_by_bot
  defp arena_match_result_field_to_atom("duration_ms"), do: :duration_ms
  defp arena_match_result_field_to_atom(_), do: nil
end

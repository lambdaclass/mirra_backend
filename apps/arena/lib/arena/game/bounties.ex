defmodule Arena.Game.Bounties do
  @moduledoc """
  Module to handle quest logic in arena application
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
        type = String.to_atom(quest.objective.match_tracking_field)

        acc + accumulate_objective_progress_by_scope(quest.objective.scope, Map.get(arena_match_result, type))
      end)

    comparator = parse_comparator(quest.objective.comparison)

    comparator.(progress, quest.objective.value)
  end

  defp filter_results_that_meet_quest_conditions(arena_match_results, conditions) do
    Enum.filter(arena_match_results, fn arena_match_result ->
      Enum.all?(conditions, fn condition ->
        type = String.to_atom(condition.match_tracking_field)
        value = condition.value
        arena_match_result_value = Map.get(arena_match_result, type)

        comparator = parse_comparator(condition.comparison)

        comparator.(arena_match_result_value, value)
      end)
    end)
  end
end

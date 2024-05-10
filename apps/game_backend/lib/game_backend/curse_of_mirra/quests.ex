defmodule GameBackend.CurseOfMirra.Quests do
  @moduledoc """

  """
  alias GameBackend.Repo
  alias GameBackend.Quests.QuestDescription
  alias GameBackend.Matches.ArenaMatchResult
  alias Ecto.Multi
  import Ecto.Query

  defmacrop custom_where_macro(queryable, binding, field_name, operator, value) do
    {:where, [],
     [
       queryable,
       [
         {{:^, [], [binding]}, {:relation, [], Elixir}}
       ],
       {operator, [context: Elixir, import: Kernel],
        [
          {:field, [], [{:relation, [], Elixir}, {:^, [], [field_name]}]},
          {:^, [], [value]}
        ]}
     ]}
  end

  def upsert_quests(quests_params) do
    {multi, _acc} =
      Enum.reduce(quests_params, {Multi.new(), 0}, fn quest_param, {multi, acc} ->
        quest_changeset = QuestDescription.changeset(%QuestDescription{}, quest_param)

        multi = Multi.insert(multi, {:insert_quest, acc}, quest_changeset)

        {multi, acc + 1}
      end)

    Repo.transaction(multi)
  end

  def build_query_from_quest_description(%QuestDescription{} = quest_description) do
    base_query =
      from(amr in ArenaMatchResult,
        as: :amr
      )

    Enum.reduce(quest_description.quest_objectives, base_query, fn quest_objective, query ->
      type = String.to_atom(quest_objective["type"])
      comparator = quest_objective["comparison"] |> parse_comparator()
      value = quest_objective["value"]
      custom_where(query, :amr, type, comparator, value)
    end)
  end

  defp parse_comparator("equal"), do: :==
  defp parse_comparator("greater"), do: :>

  for operator <- [:!=, :<, :<=, :==, :>, :>=, :ilike, :in, :like] do
    defp custom_where(queryable, binding, field_name, unquote(operator), value) do
      custom_where_macro(queryable, binding, field_name, unquote(operator), value)
    end
  end
end

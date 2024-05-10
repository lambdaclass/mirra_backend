defmodule GameBackend.CurseOfMirra.Quests do
  @moduledoc """

  """
  alias GameBackend.Quests.DailyQuest
  alias GameBackend.Repo
  alias GameBackend.Quests.Quest
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
        quest_changeset = Quest.changeset(%Quest{}, quest_param)

        multi = Multi.insert(multi, {:insert_quest, acc}, quest_changeset)

        {multi, acc + 1}
      end)

    Repo.transaction(multi)
  end

  def build_query_from_quest_description(%Quest{} = quest_description, user_id) do
    base_query =
      from(amr in ArenaMatchResult,
        as: :amr,
        # Fixme results should belong to User and no GoogleUser
        join: google_user in assoc(amr, :user),
        join: user in assoc(google_user, :user),
        where: user.id == ^user_id
      )
      |> filter_by_quest_duration(quest_description)

    Enum.reduce(quest_description.quest_objectives, base_query, fn quest_objective, query ->
      type = String.to_atom(quest_objective["type"])
      comparator = quest_objective["comparison"] |> parse_comparator()
      value = quest_objective["value"]
      custom_where(query, :amr, type, comparator, value)
    end)
  end

  defp parse_comparator("equal"), do: :==
  defp parse_comparator("greater"), do: :>
  defp parse_comparator("lesser"), do: :<

  defp filter_by_quest_duration(base_query, %{type: "daily"}) do
    naive_today = NaiveDateTime.utc_now()
    start_of_date = NaiveDateTime.beginning_of_day(naive_today)
    end_of_date = NaiveDateTime.end_of_day(naive_today)

    where(base_query, [{:amr, amr}], amr.inserted_at > ^start_of_date and amr.inserted_at < ^end_of_date)
  end

  defp filter_by_quest_duration(base_query, _) do
    base_query
  end

  for operator <- [:!=, :<, :<=, :==, :>, :>=, :ilike, :in, :like] do
    defp custom_where(queryable, binding, field_name, unquote(operator), value) do
      custom_where_macro(queryable, binding, field_name, unquote(operator), value)
    end
  end

  def get_quests_by_type(type) do
    q =
      from(qd in Quest,
        where: qd.type == ^type
      )

    Repo.all(q)
  end

  def add_quest_to_user_id(user_id, amount, type) do
    available_quests =
      get_quests_by_type(type)
      |> Enum.shuffle()

    {multi, _quests} =
      Enum.reduce(1..amount, {Multi.new(), available_quests}, fn _index, {multi, [quest | next_quests]} ->
        attrs = %{
          user_id: user_id,
          quest_id: quest.id
        }

        changeset = DailyQuest.changeset(%DailyQuest{}, attrs)

        multi = Multi.insert(multi, {:insert_user_quest, user_id, quest.id}, changeset)

        {multi, next_quests}
      end)

    Repo.transaction(multi)
  end
end

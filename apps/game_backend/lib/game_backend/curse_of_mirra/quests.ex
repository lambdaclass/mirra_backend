defmodule GameBackend.CurseOfMirra.Quests do
  @moduledoc """
    Module to work with quest logic
  """
  alias GameBackend.Users.GoogleUser
  alias GameBackend.Users.User
  alias GameBackend.Quests.DailyQuest
  alias GameBackend.Repo
  alias GameBackend.Quests.Quest
  alias Ecto.Multi
  import Ecto.Query

  @doc """
  Get a %Quest{} by the config_id field

  ## Examples

      iex>get_quest_by_config_id(4)
      %Quest{config_id: 4}

  """
  def get_quest_by_config_id(quest_config_id) do
    Repo.get_by(Quest, config_id: quest_config_id)
  end

  @doc """
  Get all %Quest{} by the type field that doesn't have a valid daily quest

  a valid daily quest means:
  - the inserted at is inside the current day period
  - It hasn't been completed

  ## Examples

      iex>get_user_missing_quests_by_type(user_id, "daily")
      [%Quest{type: "daily"}]
  """
  def get_user_missing_quests_by_type(user_id, type) do
    naive_today = NaiveDateTime.utc_now()
    start_of_date = NaiveDateTime.beginning_of_day(naive_today)
    end_of_date = NaiveDateTime.end_of_day(naive_today)

    q =
      from(q in Quest,
        left_join: dq in DailyQuest,
        on: q.id == dq.quest_id and dq.user_id == ^user_id,
        where:
          (is_nil(dq) or dq.inserted_at < ^start_of_date or dq.inserted_at > ^end_of_date or not is_nil(dq.completed_at)) and
            q.type == ^type,
        distinct: q.id
      )

    Repo.all(q)
  end

  @doc """
  Run the quest changeset with the given attrs
  Return %Changeset{}

  ## Examples

      iex>change_quest(quest, attrs)
      %Changeset{}

  """
  def change_quest(quest, attrs) do
    Quest.changeset(quest, attrs)
  end

  @doc """
  Insert or update config quests present in the "quests_descriptions.json" file
  """
  def upsert_quests(quests_params) do
    Enum.reduce(quests_params, Multi.new(), fn quest_param, multi ->
      case get_quest_by_config_id(quest_param.config_id) do
        nil ->
          changeset = change_quest(%Quest{}, quest_param)
          Multi.insert(multi, quest_param.config_id, changeset)

        quest ->
          changeset = change_quest(quest, quest_param)
          Multi.update(multi, quest_param.config_id, changeset)
      end
    end)
    |> Repo.transaction()
  end

  def add_quest_to_user_id(user_id, amount, type) do
    available_quests =
      get_user_missing_quests_by_type(user_id, type)
      |> Enum.shuffle()

    if amount > Enum.count(available_quests) do
      {:error, :not_enough_quests_in_config}
    else
      {multi, _quests} =
        Enum.reduce(1..amount, {Multi.new(), available_quests}, fn
          _index, {multi, [quest | next_quests]} ->
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

  def get_google_user_daily_quests_completed(%GoogleUser{
        arena_match_results: arena_match_results,
        user: %User{daily_quests: daily_quests}
      }) do
    Enum.reduce(daily_quests, [], fn daily_quest, acc ->
      if completed_daily_quest?(daily_quest, arena_match_results) do
        [daily_quest | acc]
      else
        acc
      end
    end)
  end

  #####################
  #      helpers      #
  #####################

  defp parse_comparator("equal"), do: &Kernel.==/2
  defp parse_comparator("distinct"), do: &Kernel.!=/2
  defp parse_comparator("greater"), do: &Kernel.>/2
  defp parse_comparator("greater_or_equal"), do: &Kernel.>=/2
  defp parse_comparator("lesser"), do: &Kernel.</2
  defp parse_comparator("lesser_or_equal"), do: &Kernel.<=/2
  defp parse_comparator(comparator), do: raise("Comparator not implemented yet #{comparator}")

  defp accumulate_objective_progress_by_scope("day", value), do: value
  defp accumulate_objective_progress_by_scope("match", _value), do: 1

  defp completed_daily_quest?(%DailyQuest{quest: %Quest{} = quest}, arena_match_results) do
    progress =
      arena_match_results
      |> filter_results_that_meet_quest_conditions(quest.objective)
      |> Enum.reduce(0, fn arena_match_result, acc ->
        type = String.to_atom(quest.objective["match_tracking_field"])

        acc + accumulate_objective_progress_by_scope(quest.objective["scope"], Map.get(arena_match_result, type))
      end)

    comparator = parse_comparator(quest.objective["comparison"])

    comparator.(progress, quest.objective["value"])
  end

  defp filter_results_that_meet_quest_conditions(arena_match_results, conditions) do
    Enum.filter(arena_match_results, fn arena_match_result ->
      Enum.all?(conditions, fn condition ->
        type = String.to_atom(condition["match_tracking_field"])
        value = condition["value"]
        arena_match_result_value = Map.get(arena_match_result, type)

        comparator = parse_comparator(condition["comparison"])

        comparator.(arena_match_result_value, value)
      end)
    end)
  end
end

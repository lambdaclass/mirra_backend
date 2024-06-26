defmodule GameBackend.CurseOfMirra.Quests do
  @moduledoc """
    Module to work with quest logic
  """
  alias GameBackend.Utils
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Currencies
  alias GameBackend.Users.User
  alias GameBackend.Quests.UserQuest
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
  Get a list of %Quest{} by the type field

  ## Examples

      iex>list_quests_by_type("bounty")
      [%Quest{type: "bounty"}]

  """
  def list_quests_by_type(type) do
    q =
      from(q in Quest,
        where: q.type == ^type
      )

    Repo.all(q)
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
        left_join: uq in UserQuest,
        on: q.id == uq.quest_id and uq.user_id == ^user_id,
        where:
          (is_nil(uq) or uq.inserted_at < ^start_of_date or uq.inserted_at > ^end_of_date or not is_nil(uq.completed_at) or
             uq.status != "available") and
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
  Receives a UserQuest id and returns a %UserQuest{}

  ## Examples

      iex>get_user_quest(user_quest_id)
      %UserQuest{}

  """
  def get_user_quest(user_quest_id) do
    q = from(uq in UserQuest, preload: [:quest], where: uq.id == ^user_quest_id)

    Repo.one(q)
  end

  @doc """
  Receives a user id and a daily quest type.
  Returns a list of UserQuest for the given user where the status is :rerolled.

  ## Examples

      iex>get_user_today_rerolled_daily_quests(user_id)
      [%UserQuest{}]
  """
  def get_user_today_rerolled_daily_quests(user_id) do
    naive_today = NaiveDateTime.utc_now()
    start_of_date = NaiveDateTime.beginning_of_day(naive_today)
    end_of_date = NaiveDateTime.end_of_day(naive_today)

    q =
      from(uq in UserQuest,
        join: q in assoc(uq, :quest),
        preload: [:quest],
        where:
          uq.user_id == ^user_id and uq.inserted_at > ^start_of_date and uq.inserted_at < ^end_of_date and
            uq.status == ^"rerolled" and q.type == "daily"
      )

    Repo.all(q)
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

  def add_daily_quests_to_user_id(user_id, amount) do
    available_quests =
      get_user_missing_quests_by_type(user_id, "daily")
      |> Enum.shuffle()

    if amount > Enum.count(available_quests) do
      {:error, :not_enough_quests_in_config}
    else
      {multi, _quests} =
        Enum.reduce(1..amount, {Multi.new(), available_quests}, fn
          _index, {multi, [quest | next_quests]} ->
            attrs = %{
              user_id: user_id,
              quest_id: quest.id,
              status: "available"
            }

            changeset = UserQuest.changeset(%UserQuest{}, attrs)

            multi = Multi.insert(multi, {:insert_user_quest, user_id, quest.id}, changeset)

            {multi, next_quests}
        end)

      Repo.transaction(multi)
    end
  end

  def get_user_daily_quests_completed(%User{
        arena_match_results: arena_match_results,
        user_quests: user_quests
      }) do
    user_quests
    |> Enum.reduce([], fn user_quest, acc ->
      if completed_quest?(user_quest, arena_match_results) and user_quest.quest.type == "daily" do
        [user_quest | acc]
      else
        acc
      end
    end)
  end

  def reroll_daily_quest(daily_quest_id) do
    reroll_configurations = Application.get_env(:game_backend, :quest_reroll_config)

    daily_quest =
      get_user_quest(daily_quest_id)

    amount_of_rerolled_daily_quests =
      get_user_today_rerolled_daily_quests(daily_quest.user_id)
      |> Enum.count()

    reroll_costs =
      reroll_configurations.costs
      |> Enum.map(fn currency_cost_params ->
        currency =
          Currencies.get_currency_by_name_and_game!(
            currency_cost_params.quest_currency_cost_name,
            Utils.get_game_id(:curse_of_mirra)
          )

        amount =
          (currency_cost_params.quest_base_cost +
             currency_cost_params.quest_base_cost * amount_of_rerolled_daily_quests *
               reroll_configurations.reroll_multiplier)
          |> round()

        %CurrencyCost{currency_id: currency.id, amount: amount}
      end)

    get_user_missing_quests_by_type(daily_quest.user_id, daily_quest.quest.type)
    |> case do
      [] ->
        {:error, :not_enough_available_quests}

      quests ->
        new_quest =
          quests
          |> Enum.random()

        attrs = %{
          user_id: daily_quest.user_id,
          quest_id: new_quest.id,
          status: "available"
        }

        new_quest_changeset = UserQuest.changeset(%UserQuest{}, attrs)

        finish_previous_quest_changeset =
          UserQuest.changeset(daily_quest, %{
            status: "rerolled"
          })

        cond do
          daily_quest.status == "rerolled" ->
            {:error, :quest_rerolled}

          not Currencies.can_afford(daily_quest.user_id, reroll_costs) ->
            {:error, :cant_afford}

          true ->
            Multi.new()
            |> Multi.run(:deduct_currencies, fn _, _ ->
              Currencies.substract_currencies(daily_quest.user_id, reroll_costs)
            end)
            |> Multi.update(:change_previous_quest, finish_previous_quest_changeset)
            |> Multi.insert(:insert_quest, new_quest_changeset)
            |> Repo.transaction()
        end
    end
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

  def completed_quest?(%UserQuest{quest: %Quest{} = quest}, arena_match_results) do
    progress =
      arena_match_results
      |> filter_results_that_meet_quest_conditions(quest.conditions)
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

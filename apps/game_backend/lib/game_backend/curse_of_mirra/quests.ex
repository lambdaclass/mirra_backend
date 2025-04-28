defmodule GameBackend.CurseOfMirra.Quests do
  @moduledoc """
    Module to work with quest logic
  """
  alias GameBackend.Ledger
  alias GameBackend.Users
  alias GameBackend.CurseOfMirra.Quests
  alias GameBackend.Utils
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Currencies
  alias GameBackend.Quests.UserQuest
  alias GameBackend.Repo
  alias GameBackend.Quests.Quest
  alias Ecto.Multi
  import Ecto.Query

  @doc """
  Get a %Quest{} by the id field
  ## Examples
      iex>get_quest(4)
      %Quest{id: 4}
  """
  def get_quest(id) do
    Repo.get(Quest, id)
  end

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
          (is_nil(uq) or uq.inserted_at < ^start_of_date or uq.inserted_at > ^end_of_date or uq.status != "available") and
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
    |> case do
      nil ->
        {:error, :not_found}

      user_quest ->
        {:ok, user_quest}
    end
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

  def add_quests_to_user_id_by_type(user_id, type, amount) do
    available_quests =
      get_user_missing_quests_by_type(user_id, type)
      |> Enum.shuffle()

    amount_of_quest_available = Enum.count(available_quests)

    cond do
      type not in Ecto.Enum.values(GameBackend.Quests.Quest, :type) ->
        {:error, :quest_type_not_implemented}

      amount > amount_of_quest_available ->
        {:error, "Not enough quests, requested: #{amount} available: #{amount_of_quest_available}"}

      true ->
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

  def reroll_daily_quest(daily_quest) do
    reroll_configurations = Application.get_env(:game_backend, :quest_reroll_config)

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
            |> Ledger.register_currencies_spent(daily_quest.user_id, reroll_costs, "Reroll Quest")
            |> Multi.update(:change_previous_quest, finish_previous_quest_changeset)
            |> Multi.insert(:insert_quest, new_quest_changeset)
            |> Repo.transaction()
        end
    end
  end

  @doc """
  Receives a user_id and quest_id and mark it as completed and grant the quest currency
  """
  def insert_completed_user_quest(user_id, quest_id) do
    quest =
      get_quest(quest_id)

    user_quest_changeset =
      UserQuest.changeset(%UserQuest{}, %{
        completed: true,
        completed_at: DateTime.utc_now(),
        status: "completed",
        user_id: user_id,
        quest_id: quest_id
      })

    currency = Currencies.get_currency_by_name_and_game(quest.reward["currency"], Utils.get_game_id(:curse_of_mirra))

    Multi.new()
    |> Multi.insert(:insert_completed_quest, user_quest_changeset)
    |> Ledger.register_currency_earned(
      user_id,
      [%{currency_id: currency.id, amount: quest.reward["amount"]}],
      "Completed Quest Reward"
    )
    |> Repo.transaction()
  end

  def get_user_quest_progress(%UserQuest{quest: %Quest{type: :milestone}} = milestone_quest, user) do
    user.user_quests
    |> Enum.count(fn %UserQuest{} = user_quest ->
      NaiveDateTime.diff(user_quest.inserted_at, milestone_quest.inserted_at, :day) == 0 and
        user_quest.status == "completed" and
        user_quest.quest.type == :daily
    end)
  end

  def get_user_quest_progress(%UserQuest{quest: %Quest{} = quest} = user_quest, user) do
    arena_match_results =
      if quest.type == :daily do
        Enum.filter(user.arena_match_results, fn arena_match_result ->
          user_quest.activated_at &&
            NaiveDateTime.compare(arena_match_result.inserted_at, user_quest.activated_at) == :gt &&
            NaiveDateTime.diff(arena_match_result.inserted_at, user_quest.inserted_at, :day) == 0
        end)
      else
        user.arena_match_results
      end

    arena_match_results
    |> filter_results_that_meet_quest_conditions(quest.conditions)
    |> Enum.reduce(0, fn arena_match_result, acc ->
      type = arena_match_result_field_to_atom(quest.objective["match_tracking_field"])
      # We won't accumulate progress if the objective has a wrong field getter
      accumulate_objective_progress_by_scope(quest.objective["scope"], Map.get(arena_match_result, type))
      |> case do
        nil ->
          acc

        progress ->
          acc + progress
      end
    end)
  end

  def complete_user_quest(user, user_quest) do
    updated_user_quest_changeset =
      UserQuest.changeset(user_quest, %{
        completed: true,
        completed_at: DateTime.utc_now(),
        status: "completed"
      })

    currency =
      Currencies.get_currency_by_name_and_game(user_quest.reward["currency"], Utils.get_game_id(:curse_of_mirra))

    Multi.new()
    |> Multi.run(:check_quest_completed, fn _, _ ->
      if user_quest.status == "available" and Quests.completed_quest?(user_quest, user) do
        {:ok, :quest_completed}
      else
        {:error, :unfinished_quest}
      end
    end)
    |> Multi.update(:update_user_quest, updated_user_quest_changeset)
    |> Multi.run(:maybe_activate_quest, fn _, _ ->
      Enum.find(user.user_quests, fn deactivated_user_quest ->
        is_nil(deactivated_user_quest.activated_at) && deactivated_user_quest.quest.type == user_quest.quest.type
      end)
      |> case do
        nil ->
          {:ok, :no_quests_left}

        user_quest ->
          user_quest
          |> UserQuest.changeset(%{activated_at: NaiveDateTime.utc_now()})
          |> GameBackend.Repo.update()
      end
    end)
    |> Ledger.register_currency_earned(
      user.id,
      [%{currency_id: currency.id, amount: user_quest.reward["amount"]}],
      "Completed Quest Reward"
    )
    |> Multi.run(:updated_user, fn _, _ ->
      Users.get_user_by_id_and_game_id(user.id, user.game_id)
    end)
    |> Repo.transaction()
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

  def completed_quest?(%UserQuest{quest: %Quest{} = quest} = user_quest, user) do
    progress = get_user_quest_progress(user_quest, user)
    comparator = parse_comparator(quest.objective["comparison"])

    comparator.(progress, quest.objective["value"])
  end

  defp filter_results_that_meet_quest_conditions(arena_match_results, conditions) do
    Enum.filter(arena_match_results, fn arena_match_result ->
      Enum.all?(conditions, fn condition ->
        type = arena_match_result_field_to_atom(condition["match_tracking_field"])

        case Map.get(arena_match_result, type) do
          # We'll result in a false value in case that the quest condition has a wrong field getter
          nil ->
            false

          arena_match_result_value ->
            comparator = parse_comparator(condition["comparison"])

            comparator.(arena_match_result_value, condition["value"])
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

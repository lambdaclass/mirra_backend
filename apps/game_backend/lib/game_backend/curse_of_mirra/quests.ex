defmodule GameBackend.CurseOfMirra.Quests do
  @moduledoc """
    Module to work with quest logic
  """
  alias GameBackend.CurseOfMirra.Quests
  alias GameBackend.Utils
  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Users.Currencies
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
          (is_nil(dq) or dq.inserted_at < ^start_of_date or dq.inserted_at > ^end_of_date or not is_nil(dq.completed_at) or
             dq.status != "available") and
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
  Receives a DailyQuest id and returns a %DailyQuest{}

  ## Examples

      iex>get_daily_quest(daily_quest_id)
      %DailyQuest{}

  """
  def get_daily_quest(daily_quest_id) do
    q = from(dq in DailyQuest, preload: [:quest], where: dq.id == ^daily_quest_id)

    Repo.one(q)
  end

  @doc """
  Receives a User id and returns all %DailyQuest{} that belongs to that user

  ## Examples

      iex>get_users_daily_quests(user_id)
      [%DailyQuest{}]

  """
  def get_users_daily_quests(user_id) do
    q = from(dq in DailyQuest, preload: [:quest], where: dq.user_id == ^user_id)

    Repo.all(q)
  end

  @doc """
  Receives a user id and a daily quest type.
  Returns a list of DailyQuest for the given user and type that were inserted today an their status are :rerolled.

  ## Examples

      iex>get_user_today_rerolled_daily_quests_by_type(user_id, "daily")
      [%Quest{type: "daily"}]
  """
  def get_user_today_rerolled_daily_quests_by_type(user_id, type) do
    naive_today = NaiveDateTime.utc_now()
    start_of_date = NaiveDateTime.beginning_of_day(naive_today)
    end_of_date = NaiveDateTime.end_of_day(naive_today)

    q =
      from(dq in DailyQuest,
        join: q in assoc(dq, :quest),
        preload: [:quest],
        where:
          dq.user_id == ^user_id and dq.inserted_at > ^start_of_date and dq.inserted_at < ^end_of_date and
            dq.status == ^"rerolled" and q.type == ^type
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
              quest_id: quest.id,
              status: "available"
            }

            changeset = DailyQuest.changeset(%DailyQuest{}, attrs)

            multi = Multi.insert(multi, {:insert_user_quest, user_id, quest.id}, changeset)

            {multi, next_quests}
        end)

      Repo.transaction(multi)
    end
  end

  def reroll_quest(daily_quest_id) do
    reroll_configurations = Application.get_env(:game_backend, :quest_reroll_config)

    daily_quest =
      Quests.get_daily_quest(daily_quest_id)

    amount_of_rerolled_daily_quests =
      Quests.get_user_today_rerolled_daily_quests_by_type(daily_quest.user_id, daily_quest.quest.type)
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

        new_quest_changeset = DailyQuest.changeset(%DailyQuest{}, attrs)

        finish_previous_quest_changeset =
          DailyQuest.changeset(daily_quest, %{
            status: "rerolled"
          })

        cond do
          daily_quest.status == "rerolled" ->
            {:error, :quest_rerolled}

          not Currencies.can_afford(daily_quest.user_id, reroll_costs) ->
            {:error, :cant_afford}

          true ->
            Multi.new()
            # Deduct currency
            |> Multi.run(:deduct_currencies, fn _, _ ->
              Currencies.substract_currencies(daily_quest.user_id, reroll_costs)
            end)
            # Update old daily quest
            |> Multi.update(:change_previous_quest, finish_previous_quest_changeset)
            # Add new daily quest
            |> Multi.insert(:insert_quest, new_quest_changeset)
            |> Repo.transaction()
        end
    end
  end
end

defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.CurseOfMirra.Quests
  alias GameBackend.Quests.DailyQuest
  alias GameBackend.Utils
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
  alias Ecto.Multi
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Repo

  def create_arena_match_results(match_id, results) do
    Multi.new()
    |> create_arena_match_results(match_id, results)
    |> add_users_to_multi(results)
    |> give_trophies(results)
    |> maybe_complete_quests()
    |> Repo.transaction()
  end

  ####################
  # Multi operations #
  ####################

  defp create_arena_match_results(multi, match_id, results) do
    Enum.reduce(results, multi, fn result, multi ->
      attrs = Map.put(result, "match_id", match_id)
      changeset = ArenaMatchResult.changeset(%ArenaMatchResult{}, attrs)
      Multi.insert(multi, {:insert, result["user_id"]}, changeset)
    end)
  end

  defp add_users_to_multi(multi, results) do
    Multi.run(multi, :get_users, fn repo, _changes_so_far ->
      users =
        Enum.map(results, fn result -> result["user_id"] end)
        |> Users.get_users_with_todays_daily_quests(repo)

      {:ok, users}
    end)
  end

  defp give_trophies(multi, results) do
    currency_config = Application.get_env(:game_backend, :currencies_config)

    Enum.reduce(results, multi, fn result, multi ->
      Multi.run(
        multi,
        {:add_trophies_to, result["user_id"]},
        fn _, %{get_users: users} ->
          user = Enum.find(users, fn user -> user.id == result["user_id"] end)

          amount_of_trophies =
            Enum.find(user.currencies, fn user_currency -> user_currency.currency.name == "Trophies" end)
            |> case do
              nil -> 0
              currency -> currency.amount
            end

          amount =
            get_amount_of_trophies_to_modify(amount_of_trophies, result["position"], currency_config)

          Currencies.add_currency_by_name_and_game!(
            user.id,
            "Trophies",
            Utils.get_game_id(:curse_of_mirra),
            amount
          )
        end
      )
    end)
  end

  defp maybe_complete_quests(multi) do
    Multi.run(multi, :insert_completed_quests_result, fn repo,
                                                         %{
                                                           get_users: users
                                                         } ->
      correctly_updated_list =
        Enum.map(users, fn
          user ->
            Quests.get_user_daily_quests_completed(user)
            |> Enum.map(fn %DailyQuest{quest: quest} = daily_quest ->
              updated_match =
                DailyQuest.changeset(daily_quest, %{
                  completed: true,
                  completed_at: DateTime.utc_now()
                })
                |> repo.update()

              inserted_currency =
                Currencies.add_currency_by_name_and_game(
                  user.id,
                  quest.reward["currency"],
                  Utils.get_game_id(:curse_of_mirra),
                  quest.reward["amount"]
                )

              get_operation_result(updated_match, inserted_currency)
            end)
        end)
        |> List.flatten()

      if Enum.empty?(correctly_updated_list) or Enum.all?(correctly_updated_list, fn {result, _} -> result == :ok end) do
        {:ok, nil}
      else
        {:error, nil}
      end
    end)
  end

  ####################
  #      Helpers     #
  ####################

  ## TODO: Properly pre-process `currencies_config` so the keys are integers and we don't need conversion
  ##    https://github.com/lambdaclass/mirra_backend/issues/601
  def get_amount_of_trophies_to_modify(current_trophies, position, currencies_config) when is_integer(position) do
    get_amount_of_trophies_to_modify(current_trophies, to_string(position), currencies_config)
  end

  def get_amount_of_trophies_to_modify(current_trophies, position, currencies_config) do
    Enum.sort_by(
      get_in(currencies_config, ["ranking_system", "ranks"]),
      fn %{"maximum_rank" => maximum} -> maximum end,
      :asc
    )
    |> Enum.find(get_in(currencies_config, ["ranking_system", "infinite_rank"]), fn %{"maximum_rank" => maximum} ->
      maximum > current_trophies
    end)
    |> Map.get(position)
  end

  defp get_operation_result({:ok, _}, {:ok, _}), do: {:ok, nil}
  defp get_operation_result(_, _), do: {:error, nil}
end

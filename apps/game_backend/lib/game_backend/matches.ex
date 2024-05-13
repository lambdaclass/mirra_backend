defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.Quests.DailyQuest
  alias GameBackend.CurseOfMirra.Quests
  alias GameBackend.Utils
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Matches.ArenaMatchResult

  def create_arena_match_results(results) do
    currency_config = Application.get_env(:game_backend, :currencies_config)

    Enum.reduce(results, Multi.new(), fn result, transaction_acc ->
      attrs = Map.put(result, "google_user_id", result["user_id"])
      changeset = ArenaMatchResult.changeset(%ArenaMatchResult{}, attrs)
      {:ok, google_user} = Users.get_google_user(result["user_id"])

      amount_of_trophies = Currencies.get_amount_of_currency_by_name(google_user.user.id, "Trophies")

      amount =
        get_amount_of_trophies_to_modify(amount_of_trophies, result["position"], currency_config)

      Multi.insert(transaction_acc, {:insert, result["user_id"]}, changeset)
      |> Multi.run(
        {:add_trophies_to, result["user_id"]},
        fn _, _ ->
          Currencies.add_currency_by_name_and_game!(
            google_user.user.id,
            "Trophies",
            Utils.get_game_id(:curse_of_mirra),
            amount
          )
        end
      )
    end)
    |> Multi.run(:get_google_users, fn repo, _changes_so_far ->
      google_users =
        Enum.map(results, fn result -> result["user_id"] end)
        |> Users.get_google_users_with_todays_daily_quests(repo)

      {:ok, google_users}
    end)
    |> Multi.run(:insert_completed_quests_result, fn repo,
                                                     %{
                                                       get_google_users: google_users
                                                     } ->
      correctly_updated_list =
        Enum.map(google_users, fn
          google_user ->
            Quests.get_google_user_daily_quests_completed(google_user)
            |> Enum.map(fn %DailyQuest{quest: quest} = daily_quest ->
              updated_match =
                DailyQuest.changeset(daily_quest, %{
                  completed: true,
                  completed_at: DateTime.utc_now()
                })
                |> repo.update()

              inserted_currency =
                Currencies.add_currency_by_name_and_game(
                  google_user.user.id,
                  quest.reward["currency"],
                  Utils.get_game_id(:curse_of_mirra),
                  quest.reward["amount"]
                )

              case {updated_match, inserted_currency} do
                {{:ok, _}, {:ok, _}} ->
                  {:ok, nil}

                {_, _} ->
                  {:error, google_user.user.id}
              end
            end)
        end)
        |> List.flatten()

      if Enum.empty?(correctly_updated_list) or Enum.all?(correctly_updated_list, fn {result, _} -> result == :ok end) do
        {:ok, nil}
      else
        {:error, nil}
      end
    end)
    |> Repo.transaction()
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
end

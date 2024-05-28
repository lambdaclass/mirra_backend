defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.CurseOfMirra.Quests
  alias GameBackend.Quests.UserQuest
  alias GameBackend.Utils
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
  alias Ecto.Multi
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Repo

  def create_arena_match_results(match_id, results) do
    Multi.new()
    |> create_arena_match_results(match_id, results)
    |> add_google_users_to_multi(results)
    |> maybe_complete_quests()
    |> give_trophies(results)
    |> process_bounties(results)
    |> Repo.transaction()
  end

  ####################
  # Multi operations #
  ####################

  defp create_arena_match_results(multi, match_id, results) do
    Enum.reduce(results, multi, fn result, multi ->
      attrs =
        Map.put(result, "google_user_id", result["user_id"])
        |> Map.put("match_id", match_id)

      changeset = ArenaMatchResult.changeset(%ArenaMatchResult{}, attrs)
      Multi.insert(multi, {:insert, result["user_id"]}, changeset)
    end)
  end

  defp add_google_users_to_multi(multi, results) do
    Multi.run(multi, :get_google_users, fn repo, _changes_so_far ->
      google_users =
        Enum.map(results, fn result -> result["user_id"] end)
        |> Users.get_google_users_with_todays_daily_quests(repo)

      {:ok, google_users}
    end)
  end

  defp give_trophies(multi, results) do
    currency_config = Application.get_env(:game_backend, :currencies_config)

    Enum.reduce(results, multi, fn result, multi ->
      Multi.run(
        multi,
        {:add_trophies_to, result["user_id"]},
        fn _, %{get_google_users: google_users} ->
          google_user = Enum.find(google_users, fn google_user -> google_user.id == result["user_id"] end)

          amount_of_trophies =
            Enum.find(google_user.user.currencies, fn user_currency -> user_currency.currency.name == "Trophies" end)
            |> case do
              nil -> 0
              currency -> currency.amount
            end

          amount =
            get_amount_of_trophies_to_modify(amount_of_trophies, result["position"], currency_config)

          Currencies.add_currency_by_name_and_game!(
            google_user.user.id,
            "Trophies",
            Utils.get_game_id(:curse_of_mirra),
            amount
          )
        end
      )
    end)
  end

  defp maybe_complete_quests(multi) do
    Multi.run(multi, :insert_completed_quests_result, fn _,
                                                         %{
                                                           get_google_users: google_users
                                                         } ->
      correctly_updated_list =
        Enum.map(google_users, fn
          google_user ->
            Quests.get_google_user_daily_quests_completed(google_user)
            |> Enum.map(fn %UserQuest{} = daily_quest ->
              complete_quest_and_insert_currency(daily_quest, google_user.user.id)
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

  defp process_bounties(multi, results) do
    Enum.filter(results, fn result -> result["bounty_quest_id"] != "" end)
    |> Enum.map(fn result -> Utils.convert_map_keys_to_atoms(result) end)
    |> Enum.reduce(multi, fn result, multi ->
      Multi.run(multi, {:process_bounty, result.user_id}, fn repo, %{get_google_users: google_users} ->
        google_user = Enum.find(google_users, fn google_user -> google_user.id == result.user_id end)

        user_quest_attrs =
          %{
            quest_id: result.bounty_quest_id,
            user_id: google_user.user.id,
            status: "available"
          }

        user_quest_changeset = UserQuest.changeset(%UserQuest{}, user_quest_attrs)

        user_quest =
          repo.insert!(user_quest_changeset)
          |> repo.preload([:quest])

        if Quests.completed_daily_quest?(user_quest, [result]) do
          complete_quest_and_insert_currency(user_quest, google_user.user.id)
        else
          UserQuest.changeset(user_quest, %{status: "lost"})
          |> repo.update()
        end
      end)
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

  defp complete_quest_and_insert_currency(daily_quest, user_id) do
    updated_match =
      UserQuest.changeset(daily_quest, %{
        completed: true,
        completed_at: DateTime.utc_now(),
        status: "completed"
      })
      |> Repo.update()

    inserted_currency =
      Currencies.add_currency_by_name_and_game(
        user_id,
        daily_quest.quest.reward["currency"],
        Utils.get_game_id(:curse_of_mirra),
        daily_quest.quest.reward["amount"]
      )

    get_operation_result(updated_match, inserted_currency)
  end
end

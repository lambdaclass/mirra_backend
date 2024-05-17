defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.Utils
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
  alias Ecto.Multi
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Matches.CharacterPrestige
  alias GameBackend.Repo

  def create_arena_match_results(match_id, results) do
    Multi.new()
    |> create_arena_match_results(match_id, results)
    |> add_google_users_to_multi(results)
    |> give_trophies(results)
    |> give_prestige(results)
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

  defp give_prestige(multi, results) do
    prestige_config = Application.get_env(:game_backend, :arena_prestige)

    Enum.reduce(results, multi, fn result, transaction_acc ->
      Multi.run(transaction_acc, {:update_prestige, result["user_id"]}, fn repo, %{get_google_users: google_users} ->
        google_user = Enum.find(google_users, fn google_user -> google_user.id == result["user_id"] end)
        prestige = Enum.find(google_user.user.character_prestiges, fn prestige -> prestige.character == result["character"] end)
        reward = match_prestige_reward(prestige, result["position"], prestige_config[:rewards])
        changes = calculate_rank_and_amount_changes(prestige, reward, prestige_config[:ranks])
        insert_or_update_prestige(repo, google_user.user.id, result["character"], changes, prestige)
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

  defp match_prestige_reward(nil, position, rewards) do
    match_prestige_reward(%{amount: 0}, position, rewards)
  end

  defp match_prestige_reward(prestige, position, rewards) do
    Map.get(rewards, position)
    |> Enum.find(fn %{min: minp, max: maxp} -> prestige.amount in minp..maxp end)
    |> Map.get(:reward)
  end

  defp calculate_rank_and_amount_changes(nil, reward, ranks) do
    calculate_rank_and_amount_changes(%{amount: 0}, reward, ranks)
  end

  defp calculate_rank_and_amount_changes(prestige, reward, ranks) when reward >= 0 do
    amount = prestige.amount + reward
    new_rank = Enum.find(ranks, fn rank -> amount in rank.min..rank.max end)
    %{rank: new_rank.rank, sub_rank: new_rank.sub_rank, amount: amount}
  end

  defp calculate_rank_and_amount_changes(prestige, reward, ranks) when reward < 0 do
    current_rank = Enum.find(ranks, fn rank -> prestige.amount in rank.min..rank.max end)
    amount = max(prestige.amount + reward, current_rank.min)
    %{amount: amount}
  end

  defp insert_or_update_prestige(repo, user_id, character, changes, nil) do
    attrs = Map.merge(changes, %{user_id: user_id, character: character})
    CharacterPrestige.insert_changeset(attrs)
    |> repo.insert()
  end

  defp insert_or_update_prestige(repo, _user_id, _character, changes, prestige) do
    CharacterPrestige.update_changeset(prestige, changes)
    |> repo.update()
  end
end

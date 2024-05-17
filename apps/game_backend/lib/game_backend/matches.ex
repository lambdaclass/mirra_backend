defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.Users
  alias Ecto.Multi
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Matches.CharacterPrestige
  alias GameBackend.Repo

  def create_arena_match_results(match_id, results) do
    Multi.new()
    |> create_arena_match_results(match_id, results)
    |> add_google_users_to_multi(results)
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

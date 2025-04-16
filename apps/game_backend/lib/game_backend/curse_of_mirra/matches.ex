defmodule GameBackend.CurseOfMirra.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.Users.Currencies
  alias GameBackend.Units
  alias GameBackend.Units.Unit

  alias GameBackend.Users
  alias GameBackend.Utils
  alias Ecto.Multi
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Repo

  @gold_rewards_per_position %{
    1 => 40,
    2 => 15,
    3 => 5
  }

  def create_arena_match_results(match_id, results) do
    Multi.new()
    |> create_arena_match_results(match_id, results)
    |> maybe_create_unit_for_user(results)
    |> add_users_to_multi(results)
    |> give_prestige(results)
    |> give_gold(results)
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
        |> Users.list_users_with_quests_and_results(repo)

      {:ok, users}
    end)
  end

  defp give_prestige(multi, results) do
    prestige_config = Application.get_env(:game_backend, :arena_prestige)

    Enum.reduce(results, multi, fn result, transaction_acc ->
      Multi.run(transaction_acc, {:update_prestige, result["user_id"]}, fn repo, %{get_users: users} ->
        user = Enum.find(users, fn user -> user.id == result["user_id"] end)

        Enum.find(user.units, fn unit -> unit.character.name == result["character"] end)
        |> case do
          nil ->
            {:error, :unit_not_found}

          unit ->
            reward = match_prestige_reward(unit, result["position"], prestige_config[:rewards])
            changes = calculate_rank_and_amount_changes(unit, reward, prestige_config[:ranks])

            {:ok, _update_unit} =
              Unit.curse_of_mirra_update_changeset(unit, changes)
              |> repo.update()

            {:ok, _update_highest_historical_prestige} =
              maybe_update_highest_prestige_for_user(user, reward)
        end
      end)
    end)
  end

  defp give_gold(multi, results) do
    multi =
      Multi.run(multi, :get_gold_currency, fn _repo, _changes ->
        Currencies.get_currency_by_name_and_game("Gold", Utils.get_game_id(:curse_of_mirra))
      end)

    Enum.reduce(results, multi, fn result, transaction_acc ->
      Multi.run(transaction_acc, {:gold_reward, result["user_id"]}, fn _repo,
                                                                       %{
                                                                         get_users: users,
                                                                         get_gold_currency: gold_currency
                                                                       } ->
        user = Enum.find(users, fn user -> user.id == result["user_id"] end)

        resulting_position = result["position"]

        if Map.has_key?(@gold_rewards_per_position, resulting_position) do
          gold_reward_amount = Map.get(@gold_rewards_per_position, resulting_position)

          Currencies.add_currency(user.id, gold_currency.id, gold_reward_amount)
        end
      end)
    end)
  end

  # TODO This is a TEMPORAL fix and should be removed as soon as we implement a check that block clients to play with characters
  # that they don't own or a way to unlock characters
  # Issue https://github.com/lambdaclass/mirra_backend/issues/751
  defp maybe_create_unit_for_user(multi, results) do
    Enum.reduce(results, multi, fn result, multi ->
      if Users.user_has_unit_with_character_name(result["user_id"], result["character"]) do
        multi
      else
        Multi.run(multi, {:insert_unit, result["user_id"], result["character"]}, fn _, _ ->
          Units.get_unit_default_values(result["character"])
          |> Map.put(:user_id, result["user_id"])
          |> Units.insert_unit()
        end)
      end
    end)
  end

  ####################
  #      Helpers     #
  ####################
  defp match_prestige_reward(unit, position, rewards) do
    Map.get(rewards, position)
    |> Enum.find(fn %{min: minp, max: maxp} -> unit.prestige in minp..maxp end)
    |> Map.get(:reward)
  end

  defp calculate_rank_and_amount_changes(unit, reward, ranks) when reward >= 0 do
    amount = unit.prestige + reward
    new_rank = Enum.find(ranks, fn rank -> amount in rank.min..rank.max end)

    %{rank: rank_name_converter(new_rank.rank), sub_rank: new_rank.sub_rank, prestige: amount}
  end

  defp calculate_rank_and_amount_changes(unit, loss_amount, ranks) when loss_amount < 0 do
    current_rank = Enum.find(ranks, fn rank -> unit.prestige in rank.min..rank.max end)
    amount = max(unit.prestige + loss_amount, current_rank.min)
    %{prestige: amount}
  end

  defp rank_name_converter("bronze"), do: 1
  defp rank_name_converter("silver"), do: 2
  defp rank_name_converter("gold"), do: 3
  defp rank_name_converter("platinum"), do: 4
  defp rank_name_converter("diamond"), do: 5
  defp rank_name_converter("champion"), do: 6
  defp rank_name_converter("grandmaster"), do: 7

  defp maybe_update_highest_prestige_for_user(user, reward) do
    if user.prestige + reward > user.highest_historical_prestige do
      Users.update_user(user, %{highest_historical_prestige: user.prestige + reward})
    else
      {:ok, :not_new_highest}
    end
  end
end

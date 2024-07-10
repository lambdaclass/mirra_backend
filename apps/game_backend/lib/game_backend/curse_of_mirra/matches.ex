defmodule GameBackend.CurseOfMirra.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.Units
  alias GameBackend.Units.Unit
  alias GameBackend.CurseOfMirra.Quests
  alias GameBackend.Users.Currencies
  alias GameBackend.Quests.UserQuest

  alias GameBackend.Utils
  alias GameBackend.Users
  alias Ecto.Multi
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Repo

  def create_arena_match_results(match_id, results) do
    Multi.new()
    |> create_arena_match_results(match_id, results)
    |> maybe_create_unit_for_user(results)
    |> add_users_to_multi(results)
    |> give_prestige(results)
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

            Unit.curse_of_mirra_update_changeset(unit, changes)
            |> repo.update()
        end
      end)
    end)
  end

  defp maybe_complete_quests(multi) do
    Multi.run(multi, :insert_completed_quests_result, fn _,
                                                         %{
                                                           get_users: users
                                                         } ->
      correctly_updated_list =
        Enum.map(users, fn
          user ->
            Quests.get_user_daily_quests_completed(user)
            |> Enum.map(fn %UserQuest{} = daily_quest ->
              complete_quest_and_insert_currency(daily_quest, user.id)
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

  defp get_operation_result({:ok, _}, {:ok, _}), do: {:ok, nil}
  defp get_operation_result(_, _), do: {:error, nil}

  defp rank_name_converter("bronze"), do: 1
  defp rank_name_converter("silver"), do: 2
  defp rank_name_converter("gold"), do: 3
  defp rank_name_converter("platinum"), do: 4
  defp rank_name_converter("diamond"), do: 5
  defp rank_name_converter("champion"), do: 6
  defp rank_name_converter("grandmaster"), do: 7

  defp complete_quest_and_insert_currency(user_quest, user_id) do
    updated_match =
      UserQuest.changeset(user_quest, %{
        completed: true,
        completed_at: DateTime.utc_now(),
        status: "completed"
      })
      |> Repo.update()

    inserted_currency =
      Currencies.add_currency_by_name_and_game(
        user_id,
        user_quest.quest.reward["currency"],
        Utils.get_game_id(:curse_of_mirra),
        user_quest.quest.reward["amount"]
      )

    get_operation_result(updated_match, inserted_currency)
  end
end

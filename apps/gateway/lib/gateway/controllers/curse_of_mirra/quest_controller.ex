defmodule Gateway.Controllers.CurseOfMirra.QuestController do
  @moduledoc """
    Controller to control currency changes in users
  """
  alias GameBackend.Utils
  alias GameBackend.Users
  alias GameBackend.CurseOfMirra.Quests
  GameBackend.Users.Currencies
  use Gateway, :controller

  action_fallback Gateway.Controllers.FallbackController

  def reroll_daily_quest(conn, %{"quest_id" => user_quest_id}) do
    with {:ok, daily_quest} <- Quests.get_user_quest(user_quest_id),
         {:ok, %{insert_quest: new_daily_quest}} <- Quests.reroll_daily_quest(daily_quest) do
      conn
      |> send_resp(200, new_daily_quest.id)
    end
  end

  def get_bounties(conn, _) do
    bounties =
      Quests.list_quests_by_type("bounty")
      |> Enum.map(fn bounty ->
        %{
          description: bounty.description,
          id: bounty.id,
          reward: bounty.reward,
          quest_type: bounty.objective["type"],
          objective: bounty.objective,
          conditions: bounty.conditions
        }
      end)

    conn
    |> send_resp(200, Jason.encode!(bounties))
  end

  def complete_bounty(conn, %{"user_id" => user_id, "quest_id" => quest_id}) do
    case Quests.insert_completed_user_quest(user_id, quest_id) do
      {:ok, _changes} ->
        conn
        |> send_resp(200, "Bounty completed")

      {:error, _, _, _} ->
        conn
        |> send_resp(400, "Error completing bounty")
    end
  end

  def add_quests(conn, %{"user_id" => user_id, "type" => type, "amount" => amount}) do
    with {:ok, _changes} <- Quests.add_quests_to_user_id_by_type(user_id, type, String.to_integer(amount)) do
      conn
      |> send_resp(200, "Quests added")
    end
  end

  def complete_quest(conn, %{"user_id" => user_id, "quest_id" => user_quest_id}) do
    with {:ok, user} <- Users.get_user_by_id_and_game_id(user_id, Utils.get_game_id(:curse_of_mirra)),
         {:ok, user_quest} <- Quests.get_user_quest(user_quest_id),
         {:ok, %{updated_user: updated_user}} <- Quests.complete_user_quest(user, user_quest) do
      conn
      |> send_resp(200, Jason.encode!(updated_user))
    end
  end
end

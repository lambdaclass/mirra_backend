defmodule Gateway.Controllers.CurseOfMirra.QuestController do
  @moduledoc """
    Controller to control currency changes in users
  """
  alias GameBackend.CurseOfMirra.Quests
  GameBackend.Users.Currencies
  use Gateway, :controller

  action_fallback Gateway.Controllers.FallbackController

  def reroll_daily_quest(conn, %{"quest_id" => user_quest_id}) do
    {:ok, %{insert_quest: user_quest}} = Quests.reroll_daily_quest(user_quest_id)

    conn
    |> send_resp(200, user_quest.id)
  end

  def get_bounties(conn, _) do
    bounties =
      Quests.list_quests_by_type("bounty")
      |> Enum.map(fn bounty ->
        %{
          description: bounty.description,
          id: bounty.id,
          reward: bounty.reward,
          quest_type: bounty.objective["type"]
        }
      end)

    conn
    |> send_resp(200, Jason.encode!(bounties))
  end
end

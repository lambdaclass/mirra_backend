defmodule Gateway.Controllers.CurseOfMirra.QuestController do
  @moduledoc """
    Controller to control currency changes in users
  """
  alias GameBackend.CurseOfMirra.Quests
  GameBackend.Users.Currencies
  use Gateway, :controller

  action_fallback Gateway.Controllers.FallbackController

  def reroll_quest(conn, %{"quest_id" => daily_quest_id}) do
    {:ok, %{insert_quest: daily_quest}} = Quests.reroll_quest(daily_quest_id)

    conn
    |> send_resp(200, daily_quest.id)
  end

  def get_bounties(conn, _) do
    bounties =
      Quests.get_quest_by_type("bounty")
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

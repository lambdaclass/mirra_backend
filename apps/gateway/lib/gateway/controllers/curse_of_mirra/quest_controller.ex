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

  def add_bounty(conn, %{"user_id" => user_id, "quest_id" => quest_id}) do
    {:ok, daily_quest} = Quests.add_quest_to_user(user_id, quest_id)

    conn
    |> send_resp(200, daily_quest.id)
  end
end

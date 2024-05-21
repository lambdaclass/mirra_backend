defmodule Gateway.Controllers.CurseOfMirra.QuestController do
  @moduledoc """
    Controller to control currency changes in users
  """
  alias GameBackend.CurseOfMirra.Quests
  GameBackend.Users.Currencies
  use Gateway, :controller

  def reroll_quest(conn, %{"quest_id" => daily_quest_id}) do
    case Quests.reroll_quest(daily_quest_id) do
      {:ok, %{insert_quest: daily_quest}} ->
        conn
        |> send_resp(200, daily_quest.id)

      {:error, :cant_afford} ->
        send_resp(conn, 400, "You can't afford this reroll")

      {:error, :quest_rerolled} ->
        send_resp(conn, 400, "Quest already rerolled")

      _ ->
        send_resp(conn, 400, "Error rerolling quest")
    end
  end
end

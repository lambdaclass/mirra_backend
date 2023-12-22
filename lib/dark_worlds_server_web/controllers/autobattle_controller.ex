defmodule DarkWorldsServerWeb.AutobattleController do
  use DarkWorldsServerWeb, :controller
  alias DarkWorldsServer.Accounts
  alias DarkWorldsServer.Autobattle

  def run_battle(conn, %{"device_client_id" => device_client_id, "target_user_id" => target_user_id}) do
    DarkWorldsServer.Accounts.get_user_by_device_client_id(device_client_id)

    case Accounts.get_user_by_device_client_id(device_client_id) do
      nil ->
        json(conn, %{error: "INEXISTENT_USER"})

      user ->
        winner = Autobattle.run_battle(user.id, target_user_id)

        json(conn, %{winner: winner})
    end
  end
end

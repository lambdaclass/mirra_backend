defmodule WebWeb.BoardLive.GameQueue do
  require Logger
  use WebWeb, :live_view

  def mount(%{"player_id" => player_id}, _session, socket) do
    {:ok, assign(socket, :player_id, player_id)}
  end

  def handle_event("join_game", %{"game_id" => game_id, "player_id" => player_id}, socket) do
    socket =
      socket
      |> put_flash(:info, "Game found, let's play!")
      |> redirect(to: ~p"/board/#{game_id}/#{player_id}")

    {:noreply, socket}
  end
end

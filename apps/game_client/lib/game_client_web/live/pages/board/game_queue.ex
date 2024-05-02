defmodule GameClientWeb.BoardLive.GameQueue do
  require Logger
  use GameClientWeb, :live_view

  def mount(
        %{"player_id" => player_id, "character" => character, "player_name" => player_name, "game_mode" => game_mode},
        _session,
        socket
      ) do
    {:ok, assign(socket, player_id: player_id, character: character, player_name: player_name, game_mode: game_mode)}
  end

  def handle_event("join_game", %{"game_id" => game_id, "player_id" => player_id}, socket) do
    socket =
      socket
      |> put_flash(:info, "Game found, let's play!")
      |> redirect(to: ~p"/board/play/#{game_id}/#{player_id}")

    {:noreply, socket}
  end
end

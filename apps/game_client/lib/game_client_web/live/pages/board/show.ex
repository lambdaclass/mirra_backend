defmodule GameClientWeb.BoardLive.Show do
  require Logger
  use GameClientWeb, :live_view

  def mount(%{"game_id" => game_id} = params, _session, socket) do
    if connected?(socket) do
      mount_connected(params, socket)
    else
      {:ok, assign(socket, game_id: game_id, game_status: :pending)}
    end
  end

  def mount_connected(%{"game_id" => game_id, "player_id" => player_id} = _params, socket) do
    {:ok, game_socket_handler_pid} =
      GameClient.ClientSocketHandler.start_link(self() |> :erlang.pid_to_list(), player_id, game_id)

    mocked_board_width = 1000
    mocked_board_height = 600

    game_data = %{0 => %{0 => player_name(player_id)}}

    {:ok,
     assign(socket,
       game_id: game_id,
       player_id: player_id,
       game_status: :running,
       ping_latency: 0,
       board_width: mocked_board_width,
       board_height: mocked_board_height,
       game_data: game_data,
       game_socket_handler_pid: game_socket_handler_pid
     )}
  end

  # The game state is empty until the 1st broadcast msg
  def handle_info({:game_event, "{}"}, socket) do
    {:noreply, socket}
  end

  def handle_info({:game_event, game_event}, socket) do
    %{event: event} = GameClient.Protobuf.GameEvent.decode(game_event)
    handle_game_event(event, socket)
  end

  def handle_event("move", direction, socket) do
    Process.send(socket.assigns.game_socket_handler_pid, {:move, direction}, [])

    {:noreply, socket}
  end

  def handle_event("attack", skill, socket) do
    Process.send(socket.assigns.game_socket_handler_pid, {:attack, skill}, [])

    {:noreply, socket}
  end

  defp player_name(player_id), do: "P#{player_id}"

  defp handle_game_event({:joined, _joined_info}, socket) do
    {:noreply, socket}
  end

  defp handle_game_event({:update, game_state}, socket) do
    players =
      game_state.players
      |> Enum.map(fn {_entity_id, entity} ->
        %{
          id: entity.id,
          category: entity.category,
          shape: entity.shape,
          name: entity.name,
          x: entity.position.x,
          y: entity.position.y,
          radius: entity.radius,
          coords: entity.vertices |> Enum.map(fn vertex -> [vertex.x, vertex.y] end),
          is_colliding: entity.is_colliding
        }
      end)

    projectiles =
      game_state.projectiles
      |> Enum.map(fn {_entity_id, entity} ->
        %{
          id: entity.id,
          category: entity.category,
          shape: entity.shape,
          name: entity.name,
          x: entity.position.x,
          y: entity.position.y,
          radius: entity.radius,
          coords: entity.vertices |> Enum.map(fn vertex -> [vertex.x, vertex.y] end),
          is_colliding: entity.is_colliding
        }
      end)

    {:noreply, push_event(socket, "updateEntities", %{entities: players ++ projectiles})}
  end

  defp handle_game_event({:ping, ping_event}, socket) do
    {:noreply, assign(socket, :ping_latency, ping_event.latency)}
  end
end

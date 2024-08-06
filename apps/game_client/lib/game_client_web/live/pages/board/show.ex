defmodule GameClientWeb.BoardLive.Show do
  require Logger
  use GameClientWeb, :live_view

  def mount(%{"game_id" => game_id} = params, session, socket) do
    if connected?(socket) do
      mount_connected(params, session["gateway_jwt"], socket)
    else
      {:ok, assign(socket, game_id: game_id, game_status: :pending)}
    end
  end

  def mount_connected(%{"game_id" => game_id, "player_id" => player_id}, gateway_jwt, socket) do
    {:ok, game_socket_handler_pid} =
      GameClient.ClientSocketHandler.start_link(self(), gateway_jwt, player_id, game_id)

    mocked_board_width = 3000
    mocked_board_height = 3000
    backend_board_size = 15_000
    back_size_to_front_ratio = backend_board_size / mocked_board_width
    map_radius = 0

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
       game_socket_handler_pid: game_socket_handler_pid,
       backend_board_size: backend_board_size,
       back_size_to_front_ratio: back_size_to_front_ratio,
       map_radius: map_radius
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

  def handle_event("use_item", item, socket) do
    send(socket.assigns.game_socket_handler_pid, {:use_item, item})
    {:noreply, socket}
  end

  def handle_event("toggle_bots", _, socket) do
    send(socket.assigns.game_socket_handler_pid, :toggle_bots)
    {:noreply, socket}
  end

  def handle_event("debug_mode", _, socket) do
    {:noreply, push_event(socket, "debug_mode", %{})}
  end

  defp player_name(player_id), do: "P#{player_id}"

  defp handle_game_event({:joined, joined_info}, socket) do
    socket =
      assign(
        socket,
        game_player_id: joined_info.player_id,
        map_radius: round(joined_info.config.map.radius / socket.assigns.back_size_to_front_ratio)
      )

    {:noreply, push_event(socket, "joinedGame", %{})}
  end

  defp handle_game_event({:update, game_state}, socket) do
    entities =
      Enum.concat([
        game_state.players,
        game_state.projectiles,
        game_state.items,
        game_state.obstacles,
        game_state.pools,
        game_state.bushes,
        game_state.crates,
        game_state.traps
      ])
      |> Enum.map(fn entity -> transform_entity_entry(entity, socket) end)

    {:noreply, push_event(socket, "updateEntities", %{entities: entities, player_id: socket.assigns.game_player_id})}
  end

  defp handle_game_event({:finished, finished_event}, socket) do
    send(socket.assigns.game_socket_handler_pid, :close)
    {:noreply, assign(socket, game_status: :finished, winner_id: finished_event.winner.id)}
  end

  defp handle_game_event({noop_event, _}, socket)
       when noop_event in [:toggle_bots, :ping, :ping_update, :bounty_selected] do
    {:noreply, socket}
  end

  defp transform_entity_entry({_entity_id, %{category: "obstacle"} = entity}, socket) do
    {_, aditional_info} = entity.aditional_info
    %{back_size_to_front_ratio: back_size_to_front_ratio, backend_board_size: backend_board_size} = socket.assigns

    %{
      id: entity.id,
      category: entity.category,
      shape: entity.shape,
      name: entity.name,
      x: entity.position.x / back_size_to_front_ratio + backend_board_size / 10,
      y: entity.position.y / back_size_to_front_ratio + backend_board_size / 10,
      radius: entity.radius / back_size_to_front_ratio,
      coords:
        entity.vertices
        |> Enum.map(fn vertex ->
          [vertex.x / back_size_to_front_ratio, vertex.y / back_size_to_front_ratio]
        end),
      is_colliding: entity.collides_with |> Enum.any?(),
      status: aditional_info.status
    }
  end

  defp transform_entity_entry({_entity_id, %{category: "player"} = entity}, socket) do
    %{back_size_to_front_ratio: back_size_to_front_ratio, backend_board_size: backend_board_size} = socket.assigns
    {_, aditional_info} = entity.aditional_info

    %{
      id: entity.id,
      category: entity.category,
      shape: entity.shape,
      name: entity.name,
      x: entity.position.x / back_size_to_front_ratio + backend_board_size / 10,
      y: entity.position.y / back_size_to_front_ratio + backend_board_size / 10,
      back_x: entity.position.x,
      back_y: entity.position.y,
      radius: entity.radius / back_size_to_front_ratio,
      coords: entity.vertices |> Enum.map(fn vertex -> [vertex.x / 5, vertex.y / 5] end),
      is_colliding: entity.collides_with |> Enum.any?(),
      visible_players: aditional_info.visible_players,
      effects: Enum.map(aditional_info.effects, fn effect -> effect.name end),
      health: aditional_info.health
    }
  end

  defp transform_entity_entry({_entity_id, entity}, socket) do
    %{back_size_to_front_ratio: back_size_to_front_ratio, backend_board_size: backend_board_size} = socket.assigns

    %{
      id: entity.id,
      category: entity.category,
      shape: entity.shape,
      name: entity.name,
      x: entity.position.x / back_size_to_front_ratio + backend_board_size / 10,
      y: entity.position.y / back_size_to_front_ratio + backend_board_size / 10,
      radius: entity.radius / back_size_to_front_ratio,
      coords:
        entity.vertices
        |> Enum.map(fn vertex ->
          [vertex.x / back_size_to_front_ratio, vertex.y / back_size_to_front_ratio]
        end),
      is_colliding: entity.collides_with |> Enum.any?()
    }
  end
end

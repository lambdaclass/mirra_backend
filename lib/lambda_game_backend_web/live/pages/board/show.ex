defmodule LambdaGameBackendWeb.BoardLive.Show do
  require Logger
  alias Phoenix.PubSub
  use LambdaGameBackendWeb, :live_view

  def mount(%{"game_id" => game_id} = params, _session, socket) do
    if connected?(socket) do
      mount_connected(params, socket)
    else
      {:ok, assign(socket, game_id: game_id, game_status: :pending)}
    end
  end

  def mount_connected(%{"game_id" => game_id, "player_id" => player_id} = _params, socket) do

    mocked_board_width = 1000
    mocked_board_height = 600

    game_data = %{0 => %{0 => player_name(player_id)}}

    PubSub.subscribe(LambdaGameBackend.PubSub, game_id)

    {:ok,
     assign(socket,
       game_id: game_id,
       player_id: player_id,
       game_status: :running,
       board_width: mocked_board_width,
       board_height: mocked_board_height,
       game_data: game_data
     )}
  end

  def handle_info(encoded_entities, socket) do

    game_data = encoded_entities |> Enum.map(fn encoded_entity ->
      decoded = LambdaGameBackend.Protobuf.Element.decode(encoded_entity)

      %{
        id: decoded.id,
        type: decoded.type,
        shape: decoded.shape,
        name: decoded.name,
        x: decoded.position.x,
        y: decoded.position.y,
        radius: decoded.radius,
        coords: decoded.vertices |> Enum.map(fn vertex -> [vertex.x, vertex.y] end),
        is_colliding: decoded.is_colliding
      }
    end)

    {:noreply, push_event(socket, "updateElements", %{elements: game_data})}
  end

  defp player_name(player_id), do: "P#{player_id}"
end

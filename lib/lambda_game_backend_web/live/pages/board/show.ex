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

  def handle_info(encoded_players, socket) do
    game_data =
      Enum.reduce(Map.keys(encoded_players), [], fn player_id, acc ->
        encoded_player = encoded_players[player_id]
        %{position: %{x: x, y: y}} = LambdaGameBackend.Protobuf.Player.decode(encoded_player)

        x = trunc(x) |> max(0) |> min(socket.assigns.board_width)
        y = trunc(y) |> max(0) |> min(socket.assigns.board_height)

        acc ++ [%{id: player_id, type: "player", shape: "circle", name: player_name(player_id), x: x, y: y, radius: 5}]
      end)

    # Mocked obstacle
    game_data =
      game_data ++
        [
          %{
            id: "obstacle_1",
            type: "obstacle",
            shape: "polygon",
            name: "O1",
            x: 120,
            y: 50,
            coords: [[80, 0], [80, 100], [30, 200], [0, 150], [0, 50]]
          }
        ]

    assigns = [
      game_data: game_data
    ]

    {:noreply, push_event(socket, "updateElements", %{elements: game_data})}
  end

  defp player_name(player_id), do: "P#{player_id}"
end

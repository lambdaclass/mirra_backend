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
    mocked_grid_rows = 10
    mocked_grid_cols = 10
    game_data = %{0 => %{0 => player_name(player_id)}}

    PubSub.subscribe(LambdaGameBackend.PubSub, game_id)

    {:ok,
     assign(socket,
       game_id: game_id,
       player_id: player_id,
       game_status: :running,
       grid_rows: mocked_grid_rows,
       grid_cols: mocked_grid_cols,
       game_data: game_data
     )}
  end

  def handle_info(encoded_players, socket) do
    game_data =
      Enum.reduce(Map.keys(encoded_players), %{}, fn player_id, acc ->
        encoded_player = encoded_players[player_id]
        %{position: %{x: x, y: y}} = LambdaGameBackend.Protobuf.Player.decode(encoded_player)

        x = trunc(x) |> max(0) |> min(9)
        y = trunc(y) |> max(0) |> min(9)

        Map.update(acc, y, %{x => player_name(player_id)}, fn players_map ->
          Map.put(players_map, x, player_name(player_id))
        end)
      end)

    assigns = [
      game_data: game_data
    ]

    {:noreply, assign(socket, assigns)}
  end

  defp player_name(player_id), do: "P#{player_id}"
end

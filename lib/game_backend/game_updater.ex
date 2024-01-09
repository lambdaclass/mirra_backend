defmodule GameBackend.GameUpdater do
  @moduledoc """
  GenServer that broadcasts the latest game update to every client
  (player websocket).
  """
  use GenServer
  alias Phoenix.PubSub

  # Time between game updates in ms
  @game_tick 30

  # API
  def move(game_pid, player_id, new_position) do
    GenServer.call(game_pid, {:move, player_id, new_position})
  end

  def join(game_pid, player_id) do
    GenServer.call(game_pid, {:join, player_id})
  end

  # Callbacks
  def init(%{players: players}) do
    game_id = self() |> :erlang.term_to_binary() |> Base58.encode()

    state =
      Enum.reduce(players, Physics.new_game(game_id), fn {player_id, _client_id}, state ->
        Physics.add_player(state, String.to_integer(player_id))
      end)
      |> Physics.add_polygon()

    Process.send_after(self(), :update_game, @game_tick)
    {:ok, state}
  end

  def handle_info(:update_game, state) do
    Process.send_after(self(), :update_game, @game_tick)

    encoded_entities =
      Enum.map(state.entities, fn {_entity_id, entity} ->
        GameBackend.Protobuf.Entity.encode(%GameBackend.Protobuf.Entity{
          id: entity.id,
          category: to_string(entity.category),
          shape: to_string(entity.shape),
          name: "Entity" <> Integer.to_string(entity.id),
          position: %GameBackend.Protobuf.Position{
            x: entity.position.x,
            y: entity.position.y
          },
          radius: entity.radius,
          vertices:
            Enum.map(entity.vertices, fn vertex ->
              %GameBackend.Protobuf.Position{
                x: vertex.x,
                y: vertex.y
              }
            end),
          is_colliding: Physics.check_collisions(entity, state.entities)
        })
      end)

    PubSub.broadcast(GameBackend.PubSub, state.game_id, encoded_entities)

    {:noreply, state}
  end

  def handle_call({:join, player_id}, _from, state) do
    {:reply, :ok, Physics.add_player(state, String.to_integer(player_id))}
  end

  def handle_call({:move, player_id, _new_position = {x, y}}, _from, state) do
    state = Physics.move_player(state, player_id |> String.to_integer(), x, y)

    {:reply, :ok, state}
  end
end

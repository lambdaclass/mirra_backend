defmodule LambdaGameBackend.GameUpdater do
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
  def init(%{player_id: player_id}) do
    state =
      StateManagerBackend.new_game()
      |> StateManagerBackend.add_player(String.to_integer(player_id))
      |> StateManagerBackend.add_polygon()

    Process.send_after(self(), :update_game, @game_tick)
    {:ok, state}
  end

  def handle_info(:update_game, state) do
    Process.send_after(self(), :update_game, @game_tick)

    encoded_entities =
      Enum.map(state.entities, fn {_entity_id, entity} ->
          LambdaGameBackend.Protobuf.Entity.encode(%LambdaGameBackend.Protobuf.Entity{
            id: entity.id,
            category: to_string(entity.category),
            shape: to_string(entity.shape),
            name: "Entity" <> Integer.to_string(entity.id),
            position: %LambdaGameBackend.Protobuf.Position{
              x: entity.position.x,
              y: entity.position.y
            },
            radius: entity.radius,
            vertices:  Enum.map(entity.vertices, fn vertex -> %LambdaGameBackend.Protobuf.Position{
              x: vertex.x,
              y: vertex.y
            } end),
            is_colliding: StateManagerBackend.check_collisions(entity, state.entities)
          })
      end)

    PubSub.broadcast(LambdaGameBackend.PubSub, _game_id = "1", encoded_entities)

    {:noreply, state}
  end

  def handle_call({:join, player_id}, _from, state) do
    {:reply, :ok, StateManagerBackend.add_player(state, String.to_integer(player_id))}
  end

  def handle_call({:move, player_id, _new_position = {x, y}}, _from, state) do
    state = StateManagerBackend.move_player(state, player_id |> String.to_integer(), x, y)

    {:reply, :ok, state}
  end
end

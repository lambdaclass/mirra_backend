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
  def join(game_pid, player_id) do
    GenServer.call(game_pid, {:join, player_id})
  end

  def move(game_pid, player_id, direction) do
    GenServer.call(game_pid, {:move, player_id, direction})
  end

  def attack(game_pid, player_id, skill) do
    GenServer.call(game_pid, {:attack, player_id, skill})
  end

  # Callbacks
  def init(%{players: players}) do
    game_id = self() |> :erlang.term_to_binary() |> Base58.encode()

    obstacle_vertices = [
      %GameBackend.Protobuf.Position{
        x: 600.0,
        y: 200.0
      },
      %GameBackend.Protobuf.Position{
        x: 700.0,
        y: 200.0
      },
      %GameBackend.Protobuf.Position{
        x: 650.0,
        y: 150.0
      }
    ]

    map = %GameBackend.Protobuf.Entity{
      id: 1000,
      category: :map,
      shape: :circle,
      name: "map",
      position: %GameBackend.Protobuf.Position{
        x: 500.0,
        y: 300.0
      },
      radius: 300.0,
      vertices: [],
      is_colliding: false,
      speed: 0.0,
      direction: %GameBackend.Protobuf.Position{
        x: 0.0,
        y: 0.0
      }
    }

    state =
      Enum.reduce(players, Physics.new_game(game_id, map), fn {player_id, _client_id}, state ->
        Physics.add_player(state, String.to_integer(player_id))
      end)
      |> Physics.add_polygon(obstacle_vertices)

    Process.send_after(self(), :update_game, @game_tick)
    {:ok, state}
  end

  def handle_info(:update_game, state) do
    Process.send_after(self(), :update_game, @game_tick)

    obstacles =
      state.entities
      |> Map.values()
      |> Enum.filter(fn entity -> entity.category == :obstacle end)

    state = Physics.move_entities(state, obstacles)

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

  def handle_call({:move, player_id, _direction = {x, y}}, _from, state) do
    state = Physics.move_player(state, player_id |> String.to_integer(), x, y)

    {:reply, :ok, state}
  end

  def handle_call({:attack, player_id, _skill}, _from, state) do
    current_player = Map.get(state.entities, String.to_integer(player_id))

    state = Physics.add_projectile(state, current_player.position, 10.0, 10.0, current_player.direction)

    {:reply, :ok, state}
  end
end

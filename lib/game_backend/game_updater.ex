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

    left_wall_vertices = [
      %GameBackend.Protobuf.Position{
        x: 000.0,
        y: 000.0
      },
      %GameBackend.Protobuf.Position{
        x: 000.0,
        y: 600.0
      },
      %GameBackend.Protobuf.Position{
        x: 50.0,
        y: 600.0
      },
      %GameBackend.Protobuf.Position{
        x: 100.0,
        y: 300.0
      },
      %GameBackend.Protobuf.Position{
        x: 50.0,
        y: 0.0
      }
    ]

    right_wall_vertices = [
      %GameBackend.Protobuf.Position{
        x: 1000.0,
        y: 600.0
      },
      %GameBackend.Protobuf.Position{
        x: 1000.0,
        y: 000.0
      },
      %GameBackend.Protobuf.Position{
        x: 950.0,
        y: 0.0
      },
      %GameBackend.Protobuf.Position{
        x: 900.0,
        y: 300.0
      },
      %GameBackend.Protobuf.Position{
        x: 950.0,
        y: 600.0
      }
    ]

    bottom_wall_vertices = [
      %GameBackend.Protobuf.Position{
        x: 000.0,
        y: 600.0
      },
      %GameBackend.Protobuf.Position{
        x: 1000.0,
        y: 600.0
      },
      %GameBackend.Protobuf.Position{
        x: 1000.0,
        y: 550.0
      },
      %GameBackend.Protobuf.Position{
        x: 500.0,
        y: 500.0
      },
      %GameBackend.Protobuf.Position{
        x: 000.0,
        y: 550.0
      }
    ]

    top_wall_vertices = [
      %GameBackend.Protobuf.Position{
        x: 000.0,
        y: 000.0
      },
      %GameBackend.Protobuf.Position{
        x: 1000.0,
        y: 000.0
      },
      %GameBackend.Protobuf.Position{
        x: 1000.0,
        y: 50.0
      },
      %GameBackend.Protobuf.Position{
        x: 500.0,
        y: 100.0
      },
      %GameBackend.Protobuf.Position{
        x: 000.0,
        y: 50.0
      }
    ]

    state =
      Enum.reduce(players, Physics.new_game(game_id), fn {player_id, _client_id}, state ->
        Physics.add_player(state, String.to_integer(player_id))
      end)
      |> Physics.add_polygon(100, left_wall_vertices)
      |> Physics.add_polygon(101, bottom_wall_vertices)
      |> Physics.add_polygon(102, right_wall_vertices)
      |> Physics.add_polygon(103, top_wall_vertices)

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

  def handle_call({:move, player_id, _new_position = {x, y}}, _from, state) do
    state = Physics.move_player(state, player_id |> String.to_integer(), x, y)

    {:reply, :ok, state}
  end
end

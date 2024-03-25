defmodule ArenaLoadTest.SocketSupervisor do
  @moduledoc """
  Socket Supervisor
  """
  use DynamicSupervisor
  alias ArenaLoadTest.SocketHandler
  alias ArenaLoadTest.GameSocketHandler

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__, max_restarts: 1)
  end

  def add_new_client(client_id) do
    SocketHandler.start_link(client_id)

    # DynamicSupervisor.start_child(
    #   __MODULE__,
    #   {SocketHandler, client_id}
    # ) |> IO.inspect(label: :aver_new_client)
  end

  def add_new_player(client_id, game_id) do
    GameSocketHandler.start_link({client_id, game_id})

    # DynamicSupervisor.start_child(
    #   __MODULE__,
    #   {GameSocketHandler, {client_id, game_id}}
    # )
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # Creates `num_clients` clients to join a game
  def spawn_players(num_clients) do
    for i <- 1..num_clients do
      IO.inspect(i, label: :aver_client_number)
      {:ok, _pid} = add_new_client(i)
    end
  end

  def server_host() do
    System.get_env("SERVER_HOST", "localhost:4000")
  end
end

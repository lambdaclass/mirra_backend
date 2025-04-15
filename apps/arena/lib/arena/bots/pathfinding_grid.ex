defmodule Arena.Bots.PathfindingGrid do
  @moduledoc """
  Generates a grid for current map.
  """
  alias Arena.Configuration
  use GenServer
  @update_interval_ms 3_600_000
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    Process.send_after(self(), :update_config, 1_000)

    {:ok, %{}}
  end

  def get_map_collision_grid(map_name, from_pid) do
    GenServer.cast(__MODULE__, {:get_map_collision_grid, map_name, from_pid})
  end

  def handle_info(:update_config, _state) do
    state =
      Configuration.get_current_maps_configuration()
      |> Enum.reduce(%{maps: []}, fn map, acc ->
        map_obstacles =
          Enum.reduce(map.obstacles, {[], 1}, fn obstacle, {obstacles_acc, current_id} ->
            # The following is only done so Rust doesn't complain about Entity type param
            updated_obstacle =
              obstacle
              |> Map.take([
                :id,
                :shape,
                :position,
                :radius,
                :vertices,
                :speed,
                :category,
                :direction,
                :is_moving,
                :name
              ])
              |> Map.put(:id, current_id)
              |> Map.put(:shape, get_shape(obstacle.shape))
              |> Map.put(:category, :obstacle)
              |> Map.put(:is_moving, false)
              |> Map.put(:direction, %{x: 0.0, y: 0.0})
              |> Map.put(:speed, 0.0)

            {obstacles_acc ++ [updated_obstacle], current_id + 1}
          end)
          |> elem(0)
          |> Enum.map(fn obstacle -> {obstacle.id, obstacle} end)
          |> Map.new()

        collision_grid =
          case AStarNative.build_collision_grid(map_obstacles) do
            {:ok, collision_grid} ->
              collision_grid

            {:error, reason} ->
              Logger.error("Grid construction failed with reason: #{inspect(reason)}")
              nil
          end

        Map.put(acc, :maps, acc.maps ++ [Map.put(map, :grid, collision_grid)])
      end)

    Process.send_after(__MODULE__, :update_config, @update_interval_ms)
    {:noreply, state}
  end

  def handle_cast({:get_map_collision_grid, map_name, from_pid}, state) do
    grid =
      Enum.find(state.maps, fn map -> map.name == map_name end)
      |> Map.get(:grid)

    send(from_pid, {:collision_grid_response, grid})

    {:noreply, state}
  end

  defp get_shape("polygon"), do: :polygon
  defp get_shape("circle"), do: :circle
  defp get_shape("line"), do: :line
  defp get_shape("point"), do: :point
  defp get_shape(_), do: nil
end

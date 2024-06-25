defmodule Arena.Game.Obstacle do
  def active_obstacle?(obstacle) do
    obstacle.aditional_info.active
  end

  def get_active_obstacles(obstacles) do
    Map.filter(obstacles, fn {_obstacle_id, obstacle} -> active_obstacle?(obstacle) end)
  end

  def handle_transition_init(obstacle) do
    current_status_params =
      Map.get(obstacle.aditional_info.statuses_cycle, String.to_existing_atom(obstacle.aditional_info.status))

    Process.send_after(
      self(),
      {:start_obstacle_transition, obstacle.id},
      current_status_params.time_until_transition_ms
    )

    update_in(obstacle, [:aditional_info], fn aditional_info ->
      aditional_info
      |> Map.put(:next_status, current_status_params.next_status)
      |> Map.put(:active, current_status_params.activate_obstacle)
    end)
  end

  def start_obstacle_transition(obstacle) do
    Process.send_after(
      self(),
      {:handle_obstacle_transition, obstacle.id},
      obstacle.aditional_info.transition_time_ms
    )

    update_in(obstacle, [:aditional_info], fn aditional_info ->
      aditional_info
      |> Map.put(:status, "transitioning")
    end)
  end

  def handle_transition(obstacle) do
    IO.inspect("transition")

    current_status_params =
      Map.get(obstacle.aditional_info.statuses_cycle, String.to_existing_atom(obstacle.aditional_info.next_status))

    Process.send_after(
      self(),
      {:start_obstacle_transition, obstacle.id},
      current_status_params.time_until_transition_ms
    )

    update_in(obstacle, [:aditional_info], fn aditional_info ->
      aditional_info
      |> Map.put(:next_status, current_status_params.next_status)
      |> Map.put(:status, obstacle.aditional_info.next_status)
      |> Map.put(:active, current_status_params.activate_obstacle)
    end)
  end
end

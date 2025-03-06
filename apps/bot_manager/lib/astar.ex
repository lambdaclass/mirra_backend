defmodule BotManager.AStar do
  alias BotManager.AStar
  defstruct [:pos, :g, :h, :f, :parent]

  @grid_cell_size 100
  @world_radius 15000
  @num_rows div(@world_radius * 2, @grid_cell_size)
  @num_cols div(@world_radius * 2, @grid_cell_size)

  def world_to_grid(%{x: x, y: y}) do
    {
      floor((y + @world_radius) / @grid_cell_size),
      floor((x + @world_radius) /  @grid_cell_size), 
    }
  end

  def grid_to_world({y, x}) do
    %{
      x: (x - div(@num_cols, 2)) * @grid_cell_size,
      y: (y - div(@num_rows, 2)) * @grid_cell_size,
    }
  end

  def a_star_shortest_path(from, to) do
    grid = Enum.reduce(0..@num_rows, %{}, fn y, acc -> 
      Map.put(acc, y, Enum.reduce(0..@num_cols, %{}, fn x, acc -> 
        # square around center of the grid
        Map.put(acc, x, x >= div(@num_cols, 2) - 3 and x <= div(@num_cols, 2) + 3 and y >= div(@num_rows, 2) - 3 and y <= div(@num_rows, 2) + 3)
      end))
    end)

    IO.inspect("Grid Generated")

    start = world_to_grid(from)
    goal = world_to_grid(to)

    IO.inspect("start and goal generated")

    start |> IO.inspect()
    goal |> IO.inspect()

    IO.inspect("Finding Path")

    {:ok, path} = a_star(start, goal, grid)

    IO.inspect("Found Path")

    path
  end


  # ---

  # Function to calculate the heuristic (Manhattan distance)
  defp heuristic({x1, y1}, {x2, y2}) do
    abs(x1 - x2) + abs(y1 - y2)
  end

  # A* search function
  def a_star(start, goal, grid) do
    open_list = [%AStar{pos: start, g: 0, h: heuristic(start, goal), f: heuristic(start, goal), parent: nil}]
    closed_list = []

    search(open_list, closed_list, goal, grid)
  end

  defp search([], _closed_list, _goal, _grid), do: {:no_path_found}

  defp search([current_node | open_list], closed_list, goal, grid) do
    # If we reach the goal
    if current_node.pos == goal do
      {:ok, reconstruct_path(current_node)}
    else
      # Move current node to closed list
      closed_list = [current_node | closed_list]

      # Generate neighbors (4-directional: up, down, left, right)
      neighbors = generate_neighbors(current_node.pos, grid)

      # For each neighbor, check if it's in the open or closed list
        open_list = Enum.reduce(neighbors, Enum.filter(open_list, fn node -> not in_closed_list?(node.pos, closed_list) end), fn neighbor, open_list ->
        if not in_closed_list?(neighbor, closed_list) do
          g = current_node.g + 1
          h = heuristic(neighbor, goal)
          f = g + h

          new_node = %AStar{
            pos: neighbor,
            g: g,
            h: h,
            f: f,
            parent: current_node
          }

          open_list = insert_in_order(open_list, new_node)
        else
          open_list
        end
      end)

      search(open_list, closed_list, goal, grid)
    end
  end

  # Reconstruct the path from the goal node to the start node
  defp reconstruct_path(node) do
    Enum.reverse(reconstruct_path_helper(node, []))
  end

  defp reconstruct_path_helper(nil, path), do: path

  defp reconstruct_path_helper(node, path) do
    reconstruct_path_helper(node.parent, [node.pos | path])
  end

  # Generate neighbors for a given node (4 directions: up, down, left, right)
  defp generate_neighbors({y, x}, grid) do
    directions = [{0, -1}, {0, 1}, {-1, 0}, {1, 0}] # Up, Down, Left, Right

    Enum.filter(directions, fn {dy, dx} ->
      ny = y + dy
      nx = x + dx
      valid_position?(ny, nx, grid)
    end)
    |> Enum.map(fn {dy, dx} -> {y + dy, x + dx} end)
  end

  # Check if a given position is valid (within the grid bounds and not an obstacle)
  defp valid_position?(y, x, grid) do
    if x < 0 or y < 0 or x >= @num_cols or y >= @num_rows, do: false, else: grid[y][x] != 1
  end

  # Check if the neighbor is already in the closed list
  defp in_closed_list?(neighbor, closed_list) do
    Enum.any?(closed_list, fn node -> node.pos == neighbor end)
  end

  # Insert a node into the open list in order based on f-value (lowest f first)
  defp insert_in_order([], new_node), do: [new_node]

  defp insert_in_order([node | rest], new_node) do
    if new_node.f < node.f do
      [new_node, node | rest]
    else
      [node | insert_in_order(rest, new_node)]
    end
  end

end

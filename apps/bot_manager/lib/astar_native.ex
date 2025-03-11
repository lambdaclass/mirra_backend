defmodule AStarNative do
  @moduledoc """
  This module will provide an interface to call a NIF that implements the A* algorithm to get the shortest path between two points..
  """

  use Rustler, otp_app: :bot_manager, crate: "astarnative"

  # When your NIF is loaded, it will override this function.
  def a_star_shortest_path(_from, _to, _collision_grid), do: :erlang.nif_error(:nif_not_loaded)

  def build_collision_grid(_obstacles), do: :erlang.nif_error(:nif_not_loaded) 
end

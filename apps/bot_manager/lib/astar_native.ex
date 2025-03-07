defmodule AStarNative do
  use Rustler, otp_app: :bot_manager, crate: "astarnative"

  # When your NIF is loaded, it will override this function.
  def a_star_shortest_path(_from, _to), do: :erlang.nif_error(:nif_not_loaded)
end

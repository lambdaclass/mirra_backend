defmodule Physics do
  @moduledoc """
  Physics
  """
  use Rustler,
    otp_app: :game_backend,
    crate: :physics

  # When loading a NIF module, dummy clauses for all NIF function are required.
  # NIF dummies usually just error out when called when the NIF is not loaded, as that should never normally happen.
  def new_game(_game_id), do: :erlang.nif_error(:nif_not_loaded)
  def add(_arg1, _arg2), do: :erlang.nif_error(:nif_not_loaded)
  def add_player(_game_state, _player_id), do: :erlang.nif_error(:nif_not_loaded)
  def move_player(_game_state, _player_id, _x, _y), do: :erlang.nif_error(:nif_not_loaded)
  def check_collisions(_entity, _entities), do: :erlang.nif_error(:nif_not_loaded)
  def add_polygon(_game_state, _id, _vertices), do: :erlang.nif_error(:nif_not_loaded)
  def move_entities(_game_state), do: :erlang.nif_error(:nif_not_loaded)
end

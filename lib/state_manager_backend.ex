defmodule StateManagerBackend do
  @moduledoc """
  StateManagerBackend
  """
  use Rustler,
    otp_app: :lambda_game_backend,
    crate: :state_manager_backend

  # When loading a NIF module, dummy clauses for all NIF function are required.
  # NIF dummies usually just error out when called when the NIF is not loaded, as that should never normally happen.
  def new_game, do: :erlang.nif_error(:nif_not_loaded)
  def add(_arg1, _arg2), do: :erlang.nif_error(:nif_not_loaded)
  def add_player(_game_state, _player_id), do: :erlang.nif_error(:nif_not_loaded)
  def move_player(_game_state, _player_id, _direc_x, _direc_y), do: :erlang.nif_error(:nif_not_loaded)
end

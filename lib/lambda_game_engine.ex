defmodule LambdaGameEngine do
  @moduledoc """
  Documentation for `LambdaGameEngine`.
  """

  use Rustler, otp_app: :lambda_game_engine, crate: :lambda_game_engine

  # When loading a NIF module, dummy clauses for all NIF function are required.
  # NIF dummies usually just error out when called when the NIF is not loaded, as that should never normally happen.
  def add(_arg1, _arg), do: :erlang.nif_error(:nif_not_loaded)
end

defmodule LambdaGameEngine do
  @moduledoc """
  Documentation for `LambdaGameEngine`.
  """

  use Rustler, otp_app: :dark_worlds_server, crate: :lambda_game_engine

  # When loading a NIF module, dummy clauses for all NIF function are required.
  # NIF dummies usually just error out when called when the NIF is not loaded, as that should never normally happen.
  @spec parse_config(binary()) :: map()
  def parse_config(_data), do: :erlang.nif_error(:nif_not_loaded)
  @spec engine_new_game(map()) :: map()
  def engine_new_game(_config), do: :erlang.nif_error(:nif_not_loaded)
  @spec add_player(map(), binary()) :: {map(), nil | pos_integer()}
  def add_player(_game, _character_name), do: :erlang.nif_error(:nif_not_loaded)
  @spec move_player(map(), pos_integer(), float()) :: map()
  def move_player(_game_state, _player_id, _angle), do: :erlang.nif_error(:nif_not_loaded)
  @spec apply_effect(map(), pos_integer(), binary()) :: map()
  def apply_effect(_game_state, _player_id, _effect_name), do: :erlang.nif_error(:nif_not_loaded)
  @spec spawn_random_loot(map()) :: {map(), nil | pos_integer()}
  def spawn_random_loot(_game_state), do: :erlang.nif_error(:nif_not_loaded)
  @spec activate_skill(map(), pos_integer(), binary(), map()) :: map()
  def activate_skill(_game_state, _player_id, _skill_key, _skill_params), do: :erlang.nif_error(:nif_not_loaded)
  @spec activate_inventory(map(), pos_integer(), pos_integer()) :: map()
  def activate_inventory(_game_state, _player_id, _inventory_at), do: :erlang.nif_error(:nif_not_loaded)
  @spec game_tick(map(), pos_integer()) :: map()
  def game_tick(_game_state, _time_diff), do: :erlang.nif_error(:nif_not_loaded)
end

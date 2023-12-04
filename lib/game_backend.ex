defmodule GameBackend do
  @moduledoc """
  Documentation for `GameBackend`.
  """

  use Rustler, otp_app: :dark_worlds_server, crate: :game_backend

  # When loading a NIF module, dummy clauses for all NIF function are required.
  # NIF dummies usually just error out when called when the NIF is not loaded, as that should never normally happen.
  @spec parse_config(binary()) :: map()
  def parse_config(_data), do: :erlang.nif_error(:nif_not_loaded)
  @spec new_game(map()) :: map()
  def new_game(_config), do: :erlang.nif_error(:nif_not_loaded)
  @spec add_player(map(), binary()) :: {map(), nil | pos_integer()}
  def add_player(_game, _character_name), do: :erlang.nif_error(:nif_not_loaded)
  @spec move_player(map(), pos_integer(), float(), boolean()) :: map()
  def move_player(_game_state, _player_id, _angle, _moving), do: :erlang.nif_error(:nif_not_loaded)
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

  defmodule Board do
    defstruct []
  end

  defmodule Character do
    defstruct []
  end

  defmodule Game do
    defstruct [:players, :board]
  end

  defmodule Player do
    defstruct [
      :id,
      :health,
      :position,
      :status,
      :action,
      :aoe_position,
      :kill_count,
      :death_count,
      :basic_skill_cooldown_left,
      :skill_1_cooldown_left,
      :skill_2_cooldown_left,
      :skill_3_cooldown_left,
      :skill_4_cooldown_left,
      :character_name,
      :effects,
      :direction,
      :body_size,
      :action_duration_ms
    ]
  end

  defmodule Projectile do
    defstruct [
      :id,
      :position,
      :direction,
      :speed,
      :range,
      :player_id,
      :damage,
      :remaining_ticks,
      :projectile_type,
      :status,
      :last_attacked_player_id,
      :pierce,
      :skill_name
    ]
  end

  defmodule Skill do
    defstruct []
  end

  defmodule Position do
    defstruct [:x, :y]
  end

  defmodule RelativePosition do
    defstruct [:x, :y]
  end
end

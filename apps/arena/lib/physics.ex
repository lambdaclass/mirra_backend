defmodule Physics do
  @moduledoc """
  Physics
  """
  use Rustler,
    otp_app: :arena,
    crate: :physics

  # When loading a NIF module, dummy clauses for all NIF function are required.
  # NIF dummies usually just error out when called when the NIF is not loaded, as that should never normally happen.
  def add(_arg1, _arg2), do: :erlang.nif_error(:nif_not_loaded)
  def check_collisions(_entity, _entities), do: :erlang.nif_error(:nif_not_loaded)

  def move_entities(_entities, _ticks_to_move, _external_wall, _obstacles),
    do: :erlang.nif_error(:nif_not_loaded)

  def move_entity(_entity, _ticks_to_move, _external_wall, _obstacles), do: :erlang.nif_error(:nif_not_loaded)
  def add_angle_to_direction(_direction, _angle), do: :erlang.nif_error(:nif_not_loaded)

  def calculate_triangle_vertices(_starting_point, _direction, _range, _angle),
    do: :erlang.nif_error(:nif_not_loaded)

  def get_direction_from_positions(_position_a, _position_b),
    do: :erlang.nif_error(:nif_not_loaded)

  def calculate_speed(_position_a, _position_b, _duration_ms),
    do: :erlang.nif_error(:nif_not_loaded)

  def nearest_entity_direction(_entity, _entities), do: :erlang.nif_error(:nif_not_loaded)
end

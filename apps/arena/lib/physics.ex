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

  def move_entity(_entity, _ticks_to_move, _external_wall, _obstacles),
    do: :erlang.nif_error(:nif_not_loaded)

  def move_entity(_entity, _ticks_to_move, _external_wall), do: :erlang.nif_error(:nif_not_loaded)

  def get_closest_available_position(_entity, _new_position, _external_wall, _obstacles),
    do: :erlang.nif_error(:nif_not_loaded)

  def move_entity_to_direction(_entity, _direction, _amount, _external_wall, _obstacles),
    do: :erlang.nif_error(:nif_not_loaded)

  def add_angle_to_direction(_direction, _angle), do: :erlang.nif_error(:nif_not_loaded)

  def calculate_triangle_vertices(_starting_point, _direction, _range, _angle),
    do: :erlang.nif_error(:nif_not_loaded)

  def get_direction_from_positions(_position_a, _position_b),
    do: :erlang.nif_error(:nif_not_loaded)

  def calculate_duration(_position_a, _position_b, _speed),
    do: :erlang.nif_error(:nif_not_loaded)

  def distance_between_entities(_entity, _entities), do: :erlang.nif_error(:nif_not_loaded)

  def nearest_entity_position_in_range(_entity, _entities, _range), do: :erlang.nif_error(:nif_not_loaded)
end

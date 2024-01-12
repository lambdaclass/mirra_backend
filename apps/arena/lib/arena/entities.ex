defmodule Arena.Entities do
  @moduledoc """
  Entities manager.
  """

  def new_player(id) do
    %{
      id: id,
      category: :player,
      shape: :circle,
      name: "Player" <> Integer.to_string(id),
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: 50.0,
      vertices: [],
      speed: 10.0,
      direction: %{
        x: 0.0,
        y: 0.0
      }
    }
  end

  def new_projectile(id, position, direction) do
    %{
      id: id,
      category: :projectile,
      shape: :circle,
      name: "Projectile" <> Integer.to_string(id),
      position: position,
      radius: 10.0,
      vertices: [],
      speed: 30.0,
      direction: direction
    }
  end
end

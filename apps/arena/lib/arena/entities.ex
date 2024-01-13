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
      },
      aditional_info: %{
        health: 100
      }
    }
  end

  def new_projectile(id, position, direction, owner_id) do
    %{
      id: id,
      category: :projectile,
      shape: :circle,
      name: "Projectile" <> Integer.to_string(id),
      position: position,
      radius: 10.0,
      vertices: [],
      speed: 30.0,
      direction: direction,
      aditional_info: %{
        damage: 10,
        owner_id: owner_id
      }
    }
  end

  def maybe_add_custom_info(entity) when entity.category == :player do
    {:player,
     %Arena.Serialization.Player{
       health: entity.aditional_info.health
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :projectile do
    {:projectile,
     %Arena.Serialization.Projectile{
       damage: entity.aditional_info.damage,
       owner_id: entity.aditional_info.owner_id
     }}
  end

  def maybe_add_custom_info(_entity) do
    {}
  end
end

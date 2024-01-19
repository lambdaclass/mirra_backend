defmodule Arena.Entities do
  @moduledoc """
  Entities manager.
  """

  def new_player(id, skills_config) do
    ## TODO: This hardcoding is to ensure the skills are in the correct skill_key
    ##  after we have proper configuration for this we can remove this matching
    [%{name: "shot"} = skill1, %{name: "circle_bash"} = skill2] = skills_config
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
      speed: 25.0,
      direction: %{
        x: 0.0,
        y: 0.0
      },
      aditional_info: %{
        health: 100,
        skills: %{"1" => skill1, "2" => skill2}
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

  def new_external_wall(radius) do
    %{
      id: 0,
      category: :obstacle,
      shape: :circle,
      name: "ExternalWall",
      position: %{
        x: 0.0,
        y: 0.0
      },
      radius: radius,
      vertices: [],
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
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

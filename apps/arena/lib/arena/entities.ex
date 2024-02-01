defmodule Arena.Entities do
  @moduledoc """
  Entities manager.
  """
  alias Arena.Configuration

  def new_player(id, character_name, position, direction, config) do
    character = Configuration.get_character_config(character_name, config)

    %{
      id: id,
      category: :player,
      shape: :circle,
      name: "Player" <> Integer.to_string(id),
      position: position,
      radius: character.base_size,
      vertices: [],
      speed: character.base_speed,
      direction: direction,
      is_moving: false,
      aditional_info: %{
        health: character.base_health,
        skills: character.skills,
        current_actions: [],
        kill_count: 0,
        available_stamina: character.base_stamina,
        max_stamina: character.base_stamina,
        stamina_interval: character.stamina_interval,
        recharging_stamina: false
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
      speed: 40.0,
      direction: direction,
      is_moving: true,
      aditional_info: %{
        damage: 10,
        owner_id: owner_id,
        status: :ACTIVE
      }
    }
  end

  def new_external_wall(id, radius) do
    %{
      id: id,
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
      },
      is_moving: false
    }
  end

  def maybe_add_custom_info(entity) when entity.category == :player do
    {:player,
     %Arena.Serialization.Player{
       health: entity.aditional_info.health,
       current_actions: entity.aditional_info.current_actions,
       kill_count: 0,
       available_stamina: entity.aditional_info.available_stamina,
       max_stamina: entity.aditional_info.max_stamina,
       stamina_interval: entity.aditional_info.stamina_interval,
       recharging_stamina: entity.aditional_info.recharging_stamina
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :projectile do
    {:projectile,
     %Arena.Serialization.Projectile{
       damage: entity.aditional_info.damage,
       owner_id: entity.aditional_info.owner_id,
       status: entity.aditional_info.status
     }}
  end

  def maybe_add_custom_info(_entity) do
    {}
  end
end

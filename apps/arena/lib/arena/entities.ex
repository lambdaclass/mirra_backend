defmodule Arena.Entities do
  @moduledoc """
  Entities manager.
  """
  alias Arena.Configuration

  def new_player(id, character_name, position, direction, config, now) do
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
        base_health: character.base_health,
        skills: character.skills,
        current_actions: [],
        kill_count: 0,
        available_stamina: character.base_stamina,
        max_stamina: character.base_stamina,
        stamina_interval: character.stamina_interval,
        recharging_stamina: false,
        last_natural_healing_update: now,
        natural_healing_interval: character.natural_healing_interval,
        last_damage_received: now,
        last_skill_triggered: now,
        natural_healing_damage_interval: character.natural_healing_damage_interval,
        character_name: character.name,
        forced_movement: false,
        power_ups: 0,
        power_up_damage_modifier: config.power_ups.power_up.power_up_damage_modifier,
        inventory: nil,
        damage_immunity: false,
        effects: %{},
        cooldowns: %{}
      }
    }
  end

  def new_projectile(
        id,
        position,
        direction,
        owner_id,
        skill_key,
        config_params
      ) do
    %{
      id: id,
      category: :projectile,
      shape: :circle,
      name: "Projectile" <> Integer.to_string(id),
      position: position,
      radius: config_params.radius,
      vertices: [],
      speed: config_params.speed,
      direction: direction,
      is_moving: true,
      aditional_info: %{
        skill_key: skill_key,
        damage: config_params.damage,
        owner_id: owner_id,
        status: :ACTIVE,
        remove_on_collision: config_params.remove_on_collision,
        on_explode_mechanics: Map.get(config_params, :on_explode_mechanics)
      }
    }
  end

  def new_power_up(id, position, direction, owner_id, power_up) do
    %{
      id: id,
      category: :power_up,
      shape: :circle,
      name: "Power Up" <> Integer.to_string(id),
      position: position,
      radius: power_up.radius,
      vertices: [],
      speed: 0.0,
      direction: direction,
      is_moving: false,
      aditional_info: %{
        owner_id: owner_id,
        status: :AVAILABLE,
        remove_on_collision: true
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

  def new_pool(id, position, effects_to_apply, radius, owner_id) do
    %{
      id: id,
      category: :pool,
      shape: :circle,
      name: "Pool " <> Integer.to_string(id),
      position: position,
      radius: radius,
      vertices: [],
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
      },
      is_moving: false,
      aditional_info: %{
        effects_to_apply: effects_to_apply,
        owner_id: owner_id
      }
    }
  end

  def new_item(id, position, config) do
    %{
      id: id,
      category: :item,
      shape: :circle,
      name: "Item" <> Integer.to_string(id),
      position: position,
      radius: 30.0,
      vertices: [],
      speed: 0.0,
      direction: %{x: 0.0, y: 0.0},
      is_moving: false,
      aditional_info: %{
        name: config.name,
        effects: config.effects
      }
    }
  end

  def new_circular_obstacle(id, position, radius) do
    %{
      id: id,
      category: :obstacle,
      shape: :circle,
      name: "Obstacle" <> Integer.to_string(id),
      position: position,
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

  def make_circular_area(id, position, range) do
    %{
      id: id,
      category: :obstacle,
      shape: :circle,
      name: "BashDamageArea",
      position: position,
      radius: range,
      vertices: [],
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
      },
      is_moving: false
    }
  end

  def make_polygon(id, vertices) do
    %{
      id: id,
      category: :obstacle,
      shape: :polygon,
      name: "Polygon" <> Integer.to_string(id),
      position: %{x: 0.0, y: 0.0},
      radius: 0.0,
      vertices: vertices,
      speed: 0.0,
      direction: %{x: 0.0, y: 0.0},
      is_moving: false
    }
  end

  def maybe_add_custom_info(entity) when entity.category == :player do
    {:player,
     %Arena.Serialization.Player{
       health: entity.aditional_info.health,
       current_actions: entity.aditional_info.current_actions,
       kill_count: entity.aditional_info.kill_count,
       available_stamina: entity.aditional_info.available_stamina,
       max_stamina: entity.aditional_info.max_stamina,
       stamina_interval: entity.aditional_info.stamina_interval,
       recharging_stamina: entity.aditional_info.recharging_stamina,
       character_name: entity.aditional_info.character_name,
       effects: entity.aditional_info.effects,
       power_ups: entity.aditional_info.power_ups,
       inventory: entity.aditional_info.inventory,
       cooldowns: entity.aditional_info.cooldowns
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :projectile do
    {:projectile,
     %Arena.Serialization.Projectile{
       damage: entity.aditional_info.damage,
       owner_id: entity.aditional_info.owner_id,
       status: entity.aditional_info.status,
       skill_key: entity.aditional_info.skill_key
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :power_up do
    {:power_up,
     %Arena.Serialization.PowerUp{
       owner_id: entity.aditional_info.owner_id,
       status: entity.aditional_info.status
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :pool do
    {:pool,
     %Arena.Serialization.Pool{
       owner_id: entity.aditional_info.owner_id
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :item do
    {:item,
     %Arena.Serialization.Item{
       name: entity.aditional_info.name
     }}
  end

  def maybe_add_custom_info(_entity) do
    nil
  end
end

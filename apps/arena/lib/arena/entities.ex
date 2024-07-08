defmodule Arena.Entities do
  @moduledoc """
  Entities manager.
  """
  alias Arena.Configuration
  alias Arena.Game.Player
  alias Arena.Game.Crate

  def new_player(id, character_name, player_name, position, direction, config, now) do
    character = Configuration.get_character_config(character_name, config)

    %{
      id: id,
      category: :player,
      shape: :circle,
      name: player_name,
      position: position,
      radius: character.base_size,
      vertices: [],
      speed: character.base_speed,
      direction: direction,
      is_moving: false,
      aditional_info: %{
        health: character.base_health,
        base_health: character.base_health,
        max_health: character.base_health,
        base_speed: character.base_speed,
        base_radius: character.base_size,
        base_stamina_interval: character.stamina_interval,
        base_cooldown_multiplier: 1,
        skills: character.skills,
        current_actions: [],
        kill_count: 0,
        available_stamina: character.base_stamina,
        max_stamina: character.base_stamina,
        stamina_interval: character.stamina_interval,
        cooldown_multiplier: 1,
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
        pull_immunity: false,
        effects: [],
        cooldowns: %{},
        bonus_damage: 0,
        bonus_defense: 0,
        visible_players: [],
        on_bush: false,
        bounties: [],
        bounty_selected: false
      },
      collides_with: []
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
        on_explode_mechanics: Map.get(config_params, :on_explode_mechanics),
        pull_immunity: true,
        on_collide_effects: Map.get(config_params, :on_collide_effects)
      },
      collides_with: []
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
        status: :UNAVAILABLE,
        remove_on_collision: true,
        pull_immunity: true,
        power_up_damage_modifier: power_up.power_up_damage_modifier,
        power_up_health_modifier: power_up.power_up_health_modifier
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
      is_moving: false,
      aditional_info: %{}
    }
  end

  def new_pool(id, position, owner_id, skill_key, pool_params) do
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    %{
      id: id,
      category: :pool,
      shape: :circle,
      name: "Pool " <> Integer.to_string(id),
      position: position,
      radius: pool_params.radius,
      vertices: [],
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
      },
      is_moving: false,
      aditional_info: %{
        effects_to_apply: pool_params.effects_to_apply,
        owner_id: owner_id,
        effects: [],
        stat_multiplier: 0,
        duration_ms: pool_params.duration_ms + pool_params.activation_delay,
        pull_immunity: true,
        spawn_at: now,
        status: :WAITING,
        skill_key: skill_key
      },
      collides_with: []
    }
  end

  def new_item(id, position, config) do
    %{
      id: id,
      category: :item,
      shape: :circle,
      name: "Item" <> Integer.to_string(id),
      position: position,
      radius: config.radius,
      vertices: [],
      speed: 0.0,
      direction: %{x: 0.0, y: 0.0},
      is_moving: false,
      aditional_info: %{
        name: config.name,
        effects: config.effects,
        mechanics: config.mechanics,
        pull_immunity: true
      }
    }
  end

  def new_obstacle(id, %{position: position, radius: radius, shape: shape, vertices: vertices}) do
    %{
      id: id,
      category: :obstacle,
      shape: get_shape(shape),
      name: "Obstacle" <> Integer.to_string(id),
      position: position,
      radius: radius,
      vertices: vertices,
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
      },
      is_moving: false,
      aditional_info: %{}
    }
  end

  def new_bush(id, position, radius, shape, vertices \\ []) do
    %{
      id: id,
      category: :bush,
      shape: get_shape(shape),
      name: "Bush" <> Integer.to_string(id),
      position: position,
      radius: radius,
      vertices: vertices,
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
      },
      is_moving: false,
      aditional_info: %{}
    }
  end

  def new_crate(id, %{
        position: position,
        radius: radius,
        shape: shape,
        vertices: vertices,
        health: health,
        amount_of_power_ups: amount_of_power_ups,
        power_up_spawn_delay_ms: power_up_spawn_delay_ms
      }) do
    %{
      id: id,
      category: :crate,
      shape: get_shape(shape),
      name: "Crate" <> Integer.to_string(id),
      position: position,
      radius: radius,
      vertices: vertices,
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
      },
      is_moving: false,
      aditional_info: %{
        health: health,
        amount_of_power_ups: amount_of_power_ups,
        status: :FINE,
        pull_immunity: true,
        effects: [],
        power_up_spawn_delay_ms: power_up_spawn_delay_ms
      },
      collides_with: []
    }
  end

  def new_trap(
        id,
        owner_id,
        position,
        config
      ) do
    %{
      id: id,
      category: :trap,
      shape: :circle,
      name: "Trap" <> Integer.to_string(id),
      position: position,
      radius: config.radius,
      vertices: config.vertices,
      speed: 0.0,
      direction: %{x: 0.0, y: 0.0},
      is_moving: false,
      aditional_info: %{
        name: config.name,
        mechanics: config.mechanics,
        preparation_delay_ms: config.preparation_delay_ms,
        activation_delay_ms: config.activation_delay_ms,
        owner_id: owner_id,
        activate_on_proximity: config.activate_on_proximity,
        status: :PENDING
      }
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
      is_moving: false,
      aditional_info: %{}
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
      is_moving: false,
      aditional_info: %{}
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
       cooldowns: entity.aditional_info.cooldowns,
       visible_players: entity.aditional_info.visible_players,
       on_bush: entity.aditional_info.on_bush,
       forced_movement: entity.aditional_info.forced_movement
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

  def maybe_add_custom_info(entity) when entity.category == :obstacle do
    {:obstacle,
     %Arena.Serialization.Obstacle{
       color: "red"
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :pool do
    {:pool,
     %Arena.Serialization.Pool{
       owner_id: entity.aditional_info.owner_id,
       status: entity.aditional_info.status,
       effects: entity.aditional_info.effects,
       skill_key: entity.aditional_info.skill_key
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :item do
    {:item,
     %Arena.Serialization.Item{
       name: entity.aditional_info.name
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :crate do
    {:crate,
     %Arena.Serialization.Crate{
       health: entity.aditional_info.health,
       amount_of_power_ups: entity.aditional_info.amount_of_power_ups,
       status: entity.aditional_info.status
     }}
  end

  def maybe_add_custom_info(_entity) do
    nil
  end

  defp get_shape("polygon"), do: :polygon
  defp get_shape("circle"), do: :circle
  defp get_shape("line"), do: :line
  defp get_shape("point"), do: :point
  defp get_shape(_), do: nil

  def take_damage(%{category: :player} = entity, damage), do: Player.take_damage(entity, damage)
  def take_damage(%{category: :crate} = entity, damage), do: Crate.take_damage(entity, damage)

  def alive?(%{category: :player} = entity), do: Player.alive?(entity)
  def alive?(%{category: :crate} = entity), do: Crate.alive?(entity)
  def alive?(%{category: :pool} = _entity), do: true

  def update_entity(%{category: :player} = entity, game_state) do
    put_in(game_state, [:players, entity.id], entity)
  end

  def update_entity(%{category: :crate} = entity, game_state) do
    put_in(game_state, [:crates, entity.id], entity)
  end

  def update_entity(%{category: :pool} = entity, game_state) do
    put_in(game_state, [:pools, entity.id], entity)
  end

  def refresh_stamina(%{category: :player} = entity) do
    put_in(entity, [:aditional_info, :available_stamina], entity.aditional_info.max_stamina)
  end

  def refresh_cooldowns(%{category: :player} = entity) do
    put_in(entity, [:aditional_info, :cooldowns], %{})
  end
end

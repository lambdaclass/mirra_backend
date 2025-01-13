defmodule Arena.Entities do
  @moduledoc """
  Entities manager.
  """
  alias Arena.Configuration
  alias Arena.Game.Player
  alias Arena.Game.Crate

  @type new_player_params :: %{
          id: integer(),
          team: integer(),
          player_name: String.t(),
          position: %{x: float(), y: float()},
          direction: %{x: float(), y: float()},
          character_name: String.t(),
          config: map(),
          now: integer()
        }

  @spec new_player(new_player_params()) :: map()
  def new_player(params) do
    %{
      id: id,
      player_name: player_name,
      position: position,
      direction: direction,
      character_name: character_name,
      config: config,
      now: now,
      team: team
    } = params

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
        team: team,
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
        max_mana: character.base_mana,
        mana: 50,
        mana_recovery_strategy: character.mana_recovery_strategy,
        mana_recovery_time_interval_ms: character.mana_recovery_time_interval_ms,
        mana_recovery_time_amount: character.mana_recovery_time_amount,
        mana_recovery_time_last_at: now,
        mana_recovery_damage_multiplier: character.mana_recovery_damage_multiplier,
        last_natural_healing_update: now,
        natural_healing_interval: character.natural_healing_interval,
        last_damage_received: now,
        last_skill_triggered: now,
        last_skill_triggered_inside_bush: now,
        natural_healing_damage_interval: character.natural_healing_damage_interval,
        character_name: character.name,
        forced_movement: false,
        power_ups: 0,
        power_up_damage_modifier: config.game.power_up_damage_modifier,
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
        selected_bounty: nil,
        bounty_completed: false,
        current_basic_animation: 0,
        item_effects_expires_at: now,
        position: nil,
        blocked_actions: false
      },
      collides_with: []
    }
  end

  @type new_projectile_params :: %{
          id: integer(),
          owner: map(),
          position: %{x: float(), y: float()},
          direction: %{x: float(), y: float()},
          skill_key: String.t(),
          config_params: map()
        }

  @spec new_projectile(new_projectile_params()) :: map()
  def new_projectile(params) do
    %{
      id: id,
      owner: owner,
      position: position,
      direction: direction,
      skill_key: skill_key,
      config_params: config_params
    } = params

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
        owner_id: owner.id,
        owner_team: owner.aditional_info.team,
        status: :ACTIVE,
        remove_on_collision: config_params.remove_on_collision,
        on_explode_mechanics: Map.get(config_params, :on_explode_mechanics),
        pull_immunity: true,
        on_collide_effect: Map.get(config_params, :on_collide_effect)
      },
      collides_with: []
    }
  end

  def new_power_up(id, position, direction, owner_id, game_config) do
    %{
      id: id,
      category: :power_up,
      shape: :circle,
      name: "Power Up" <> Integer.to_string(id),
      position: position,
      radius: game_config.power_up_radius,
      vertices: [],
      speed: 0.0,
      direction: direction,
      is_moving: false,
      aditional_info: %{
        owner_id: owner_id,
        status: :UNAVAILABLE,
        remove_on_collision: true,
        pull_immunity: true,
        power_up_damage_modifier: game_config.power_up_damage_modifier,
        power_up_health_modifier: game_config.power_up_health_modifier
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
      aditional_info: %{
        collisionable: true,
        status: "",
        type: ""
      }
    }
  end

  def new_pool(pool_params) do
    now = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

    duration_ms =
      if pool_params[:duration_ms] && pool_params[:activation_delay] do
        pool_params.duration_ms + pool_params.activation_delay
      end

    %{
      id: pool_params.id,
      category: :pool,
      shape: get_shape(pool_params.shape),
      name: "Pool " <> Integer.to_string(pool_params.id),
      position: pool_params.position,
      radius: pool_params.radius,
      vertices: pool_params.vertices,
      speed: 0.0,
      direction: %{
        x: 0.0,
        y: 0.0
      },
      is_moving: false,
      aditional_info: %{
        effect: pool_params.effect,
        owner_id: pool_params.owner.id,
        owner_team: pool_params.owner.aditional_info.team,
        effects: [],
        stat_multiplier: 0,
        duration_ms: duration_ms,
        pull_immunity: true,
        spawn_at: now,
        status: pool_params.status,
        skill_key: pool_params.skill_key
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
        effect: config.effect,
        mechanics: config.mechanics,
        pull_immunity: true
      }
    }
  end

  def new_obstacle(id, %{position: position, radius: radius, shape: shape, vertices: vertices} = params) do
    %{
      id: id,
      category: :obstacle,
      shape: get_shape(shape),
      name: params.name,
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
        collisionable: obstacle_collisionable?(params),
        collide_with_projectiles: obstacle_collide_with_projectiles?(params),
        statuses_cycle: params.statuses_cycle,
        status: params.base_status,
        type: params.type,
        time_until_transition_start: nil,
        time_until_transition: nil
      }
    }
    |> Arena.Game.Obstacle.handle_transition_init()
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
        mechanic: config.parent_mechanic,
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

  def make_polygon_area(id, positions) do
    %{
      id: id,
      category: :obstacle,
      shape: :polygon,
      name: "BashDamageArea",
      position: %{x: 0.0, y: 0.0},
      radius: 0.0,
      vertices: positions,
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
      is_moving: false,
      aditional_info: %{}
    }
  end

  def maybe_add_custom_info(entity) when entity.category == :player do
    {:player,
     %Arena.Serialization.Player{
       health: get_in(entity, [:aditional_info, :health]),
       max_health: get_in(entity, [:aditional_info, :max_health]),
       current_actions: get_in(entity, [:aditional_info, :current_actions]),
       kill_count: get_in(entity, [:aditional_info, :kill_count]),
       available_stamina: get_in(entity, [:aditional_info, :available_stamina]),
       max_stamina: get_in(entity, [:aditional_info, :max_stamina]),
       stamina_interval: get_in(entity, [:aditional_info, :stamina_interval]),
       recharging_stamina: get_in(entity, [:aditional_info, :recharging_stamina]),
       character_name: get_in(entity, [:aditional_info, :character_name]),
       effects: get_in(entity, [:aditional_info, :effects]),
       power_ups: get_in(entity, [:aditional_info, :power_ups]),
       inventory: get_in(entity, [:aditional_info, :inventory]),
       cooldowns: get_in(entity, [:aditional_info, :cooldowns]),
       visible_players: get_in(entity, [:aditional_info, :visible_players]),
       on_bush: get_in(entity, [:aditional_info, :on_bush]),
       forced_movement: get_in(entity, [:aditional_info, :forced_movement]),
       bounty_completed: get_in(entity, [:aditional_info, :bounty_completed]),
       mana: get_in(entity, [:aditional_info, :mana]),
       current_basic_animation: get_in(entity, [:aditional_info, :current_basic_animation]),
       match_position: get_in(entity, [:aditional_info, :match_position]),
       team: get_in(entity, [:aditional_info, :team])
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :projectile do
    {:projectile,
     %Arena.Serialization.Projectile{
       damage: get_in(entity, [:aditional_info, :damage]),
       owner_id: get_in(entity, [:aditional_info, :owner_id]),
       status: get_in(entity, [:aditional_info, :status]),
       skill_key: get_in(entity, [:aditional_info, :skill_key])
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :power_up do
    {:power_up,
     %Arena.Serialization.PowerUp{
       owner_id: get_in(entity, [:aditional_info, :owner_id]),
       status: get_in(entity, [:aditional_info, :status])
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :obstacle do
    {:obstacle,
     %Arena.Serialization.Obstacle{
       color: "red",
       collisionable: get_in(entity, [:aditional_info, :collisionable]),
       status: get_in(entity, [:aditional_info, :status]),
       type: get_in(entity, [:aditional_info, :type])
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :pool do
    {:pool,
     %Arena.Serialization.Pool{
       owner_id: get_in(entity, [:aditional_info, :owner_id]),
       status: get_in(entity, [:aditional_info, :status]),
       effects: get_in(entity, [:aditional_info, :effects]),
       skill_key: get_in(entity, [:aditional_info, :skill_key])
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :item do
    {:item,
     %Arena.Serialization.Item{
       name: get_in(entity, [:aditional_info, :name])
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :crate do
    {:crate,
     %Arena.Serialization.Crate{
       health: get_in(entity, [:aditional_info, :health]),
       amount_of_power_ups: get_in(entity, [:aditional_info, :amount_of_power_ups]),
       status: get_in(entity, [:aditional_info, :status])
     }}
  end

  def maybe_add_custom_info(entity) when entity.category == :trap do
    {:trap,
     %Arena.Serialization.Trap{
       name: get_in(entity, [:aditional_info, :name]),
       owner_id: get_in(entity, [:aditional_info, :owner_id]),
       status: get_in(entity, [:aditional_info, :status])
     }}
  end

  def maybe_add_custom_info(_) do
    nil
  end

  defp get_shape("polygon"), do: :polygon
  defp get_shape("circle"), do: :circle
  defp get_shape("line"), do: :line
  defp get_shape("point"), do: :point
  defp get_shape(_), do: nil

  def take_damage(%{category: :player} = entity, damage, damage_owner_id) do
    if alive?(entity) do
      Player.take_damage(entity, damage, damage_owner_id)
    else
      entity
    end
  end

  def take_damage(%{category: :crate} = entity, damage, damage_owner_id) do
    if alive?(entity) do
      Crate.take_damage(entity, damage, damage_owner_id)
    else
      entity
    end
  end

  def alive?(%{category: :player} = entity), do: Player.alive?(entity)
  def alive?(%{category: :crate} = entity), do: Crate.alive?(entity)
  def alive?(%{category: :pool} = _entity), do: true

  def filter_damageable(source, targets) do
    Map.filter(targets, fn {_, target} -> can_damage?(source, target) end)
  end

  def filter_targetable(source, targets) do
    Map.filter(targets, fn {_, target} -> can_damage?(source, target) and visible?(source, target) end)
  end

  defp visible?(%{category: :player} = source, target), do: Player.visible?(source, target)
  defp visible?(%{category: _any} = _source, _target), do: true

  def can_damage?(source, target) do
    alive?(target) and not same_team?(source, target)
  end

  def same_team?(source, target) do
    get_team(source) == get_team(target)
  end

  defp get_team(%{category: :player} = entity), do: entity.aditional_info.team
  defp get_team(%{category: :projectile} = entity), do: entity.aditional_info.owner_team
  defp get_team(%{category: :pool} = entity), do: entity.aditional_info.owner_team
  defp get_team(%{category: category} = _entity), do: category

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

  def silence(%{category: :player} = entity, duration) do
    Process.send(self(), {:block_actions, entity.id, true}, [])
    Process.send_after(self(), {:block_actions, entity.id, false}, duration)
    put_in(entity, [:aditional_info, :blocked_actions], true)
  end

  def obstacle_collisionable?(%{type: "dynamic"} = params) do
    %{base_status: base_status, statuses_cycle: statuses_cycle} = params

    base_status_params =
      Map.get(statuses_cycle, String.to_existing_atom(base_status))

    base_status_params.make_obstacle_collisionable
  end

  def obstacle_collisionable?(_params) do
    true
  end

  def obstacle_collide_with_projectiles?(%{type: "lake"}) do
    false
  end

  def obstacle_collide_with_projectiles?(_params) do
    true
  end
end

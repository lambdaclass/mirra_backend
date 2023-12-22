defmodule DarkWorldsServer.Communication.ProtoTransform do
  alias DarkWorldsServer.Communication.Proto.ActionTracker
  alias DarkWorldsServer.Communication.Proto.Config
  alias DarkWorldsServer.Communication.Proto.GameAction
  alias DarkWorldsServer.Communication.Proto.GameCharacter
  alias DarkWorldsServer.Communication.Proto.GameCharactersConfig
  alias DarkWorldsServer.Communication.Proto.GameEffect
  alias DarkWorldsServer.Communication.Proto.GameEffectsConfig
  alias DarkWorldsServer.Communication.Proto.GameLoot
  alias DarkWorldsServer.Communication.Proto.GameLootsConfig
  alias DarkWorldsServer.Communication.Proto.GameProjectile
  alias DarkWorldsServer.Communication.Proto.GameSkill
  alias DarkWorldsServer.Communication.Proto.GameStateConfig
  alias DarkWorldsServer.Communication.Proto.Item
  alias DarkWorldsServer.Communication.Proto.KillEvent
  alias DarkWorldsServer.Communication.Proto.LootPackage
  alias DarkWorldsServer.Communication.Proto.MapModification
  alias DarkWorldsServer.Communication.Proto.Mechanic
  alias DarkWorldsServer.Communication.Proto.Modification
  alias DarkWorldsServer.Communication.Proto.Move
  alias DarkWorldsServer.Communication.Proto.OldKillEvent
  alias DarkWorldsServer.Communication.Proto.OldPlayer, as: ProtoPlayer
  alias DarkWorldsServer.Communication.Proto.OldPosition, as: ProtoPosition
  alias DarkWorldsServer.Communication.Proto.OldProjectile, as: ProtoProjectile
  alias DarkWorldsServer.Communication.Proto.Player
  alias DarkWorldsServer.Communication.Proto.PlayerAction
  alias DarkWorldsServer.Communication.Proto.PlayerInformation, as: ProtoPlayerInformation
  alias DarkWorldsServer.Communication.Proto.RelativePosition, as: ProtoRelativePosition
  alias DarkWorldsServer.Communication.Proto.SkillCooldown
  alias DarkWorldsServer.Communication.Proto.UseInventory
  alias DarkWorldsServer.Communication.Proto.UseSkill
  alias GameBackend.Player, as: GamePlayer
  alias GameBackend.Position, as: GamePosition
  alias GameBackend.Projectile, as: GameProjectile
  alias GameBackend.RelativePosition, as: GameRelativePosition

  @behaviour Protobuf.TransformModule

  ###########
  # ENCODES #
  ###########

  @impl true
  def encode({name, mechanic}, Mechanic) do
    %Mechanic{
      name: mechanic_name_encode(name)
    }
    |> Map.merge(mechanic)
  end

  def encode({modifier, value}, Modification) do
    %Modification{
      value: value,
      modifier: modifier_encode(modifier)
    }
  end

  def encode(%GamePosition{} = position, ProtoPosition) do
    %{x: x, y: y} = position
    %ProtoPosition{x: x, y: y}
  end

  def encode(%GameRelativePosition{} = position, ProtoRelativePosition) do
    %{x: x, y: y} = position
    %ProtoRelativePosition{x: x, y: y}
  end

  def encode(%GamePlayer{} = player, ProtoPlayer) do
    %GamePlayer{
      id: id,
      health: health,
      position: position,
      status: status,
      action: action,
      aoe_position: aoe_position,
      kill_count: kill_count,
      death_count: death_count,
      basic_skill_cooldown_left: basic_skill_cooldown_left,
      skill_1_cooldown_left: skill_1_cooldown_left,
      skill_2_cooldown_left: skill_2_cooldown_left,
      skill_3_cooldown_left: skill_3_cooldown_left,
      skill_4_cooldown_left: skill_4_cooldown_left,
      character_name: name,
      effects: effects,
      direction: direction,
      body_size: body_size,
      inventory: inventory,
      speed: speed,
      available_burst_loads: available_burst_loads
    } = player

    %ProtoPlayer{
      id: id,
      health: health,
      position: position,
      status: player_old_status_encode(status),
      action: player_action_encode(action),
      aoe_position: aoe_position,
      kill_count: kill_count,
      death_count: death_count,
      basic_skill_cooldown_left: basic_skill_cooldown_left,
      skill_1_cooldown_left: skill_1_cooldown_left,
      skill_2_cooldown_left: skill_2_cooldown_left,
      skill_3_cooldown_left: skill_3_cooldown_left,
      skill_4_cooldown_left: skill_4_cooldown_left,
      character_name: name,
      effects: effects,
      direction: direction,
      body_size: body_size,
      inventory: inventory,
      speed: speed,
      available_burst_loads: available_burst_loads
    }
  end

  def encode(player, Player) do
    %Player{
      id: player.id,
      position: player.position,
      health: player.health,
      speed: player.speed,
      size: player.size,
      direction: player.direction,
      status: player_status_encode(player.status),
      kill_count: player.kill_count,
      death_count: player.death_count,
      action: player.action,
      cooldowns: player.cooldowns,
      effects: Enum.map(player.effects, fn {effect, _} -> effect end),
      character_name: player.character.name
    }
  end

  def encode(%GameProjectile{} = projectile, ProtoProjectile) do
    %{
      id: id,
      position: position,
      direction: direction,
      speed: speed,
      range: range,
      player_id: player_id,
      damage: damage,
      remaining_ticks: remaining_ticks,
      projectile_type: projectile_type,
      status: status,
      last_attacked_player_id: last_attacked_player_id,
      pierce: pierce,
      skill_name: skill_name
    } = projectile

    %ProtoProjectile{
      id: id,
      position: position,
      direction: direction,
      speed: speed,
      range: range,
      player_id: player_id,
      damage: damage,
      remaining_ticks: remaining_ticks,
      projectile_type: projectile_encode(projectile_type),
      status: projectile_status_encode(status),
      last_attacked_player_id: last_attacked_player_id,
      pierce: pierce,
      skill_name: skill_name
    }
  end

  def encode({killed_by, killed}, OldKillEvent) do
    %OldKillEvent{killed_by: killed_by, killed: killed}
  end

  def encode({{killed_by, killed_by_id}, killed}, KillEvent) do
    %KillEvent{killed_by_entity: kill_entity_encode(killed_by), killed_by_id: killed_by_id, killed: killed}
  end

  def encode({killed_by, killed}, KillEvent) do
    %KillEvent{killed_by_entity: kill_entity_encode(killed_by), killed: killed}
  end

  def encode(%ProtoPlayerInformation{} = player_information, ProtoPlayerInformation) do
    player_information
  end

  def encode(loot, LootPackage) do
    %LootPackage{
      id: loot.id,
      loot_type: loot_type_encode(loot.loot_type),
      position: loot.position
    }
  end

  def encode(item, Item) do
    %Item{
      id: item.id,
      name: item.name,
      size: item.size,
      position: item.position
    }
  end

  def encode(%{action: {action_enum, action_skill_key}}, PlayerAction) do
    %PlayerAction{
      action: player_action_enum_encode(action_enum),
      action_skill_key: action_skill_key
    }
  end

  def encode(%{action: action_enum}, PlayerAction) do
    %PlayerAction{action: player_action_enum_encode(action_enum)}
  end

  def encode({skill_key, cooldown_ms}, SkillCooldown) do
    %SkillCooldown{
      skill_key: skill_key,
      cooldown_ms: cooldown_ms
    }
  end

  def encode(action, ActionTracker) do
    %ActionTracker{
      player_action: action,
      duration: action.duration
    }
  end

  def encode(data, _struct) do
    data
  end

  ###########
  # DECODES #
  ###########

  def decode(config, Config) do
    config
  end

  def decode(config, GameCharactersConfig) do
    config
  end

  def decode(config, GameEffectsConfig) do
    config
  end

  def decode(config, GameStateConfig) do
    config
  end

  def decode(config, MapModification) do
    config
  end

  def decode(config, GameLootsConfig) do
    config
  end

  def decode(config, GameProjectilesConfig) do
    config
  end

  def decode(config, GameCharacter) do
    config
  end

  def decode(config, GameEffect) do
    config
  end

  def decode(config, GameLoot) do
    config
  end

  def decode(config, GameProjectile) do
    config
  end

  @impl Protobuf.TransformModule
  def decode(%GameSkill{} = config, GameSkill) do
    config
  end

  @impl Protobuf.TransformModule
  def decode(value, GameAction) do
    value
  end

  @impl Protobuf.TransformModule
  def decode(value, UseSkill) do
    value
  end

  @impl Protobuf.TransformModule
  def decode(value, Move) do
    value
  end

  @impl Protobuf.TransformModule
  def decode(value, UseInventory) do
    value
  end

  @impl Protobuf.TransformModule
  def decode(%ProtoPosition{} = position, ProtoPosition) do
    %{x: x, y: y} = position
    %GamePosition{x: x, y: y}
  end

  @impl Protobuf.TransformModule
  def decode(%ProtoRelativePosition{} = position, ProtoRelativePosition) do
    %{x: x, y: y} = position
    %GameRelativePosition{x: x, y: y}
  end

  def decode(%ProtoPlayer{} = player, ProtoPlayer) do
    %ProtoPlayer{
      id: id,
      health: health,
      position: position,
      status: status,
      action: action,
      aoe_position: aoe_position,
      kill_count: kill_count,
      death_count: death_count,
      basic_skill_cooldown_left: basic_skill_cooldown_left,
      skill_1_cooldown_left: skill_1_cooldown_left,
      skill_2_cooldown_left: skill_2_cooldown_left,
      skill_3_cooldown_left: skill_3_cooldown_left,
      skill_4_cooldown_left: skill_4_cooldown_left,
      character_name: name,
      effects: effects,
      direction: direction,
      body_size: body_size,
      inventory: inventory,
      available_burst_loads: available_burst_loads
    } = player

    %GamePlayer{
      id: id,
      health: health,
      position: position,
      status: player_old_status_decode(status),
      action: player_action_decode(action),
      aoe_position: aoe_position,
      kill_count: kill_count,
      death_count: death_count,
      basic_skill_cooldown_left: basic_skill_cooldown_left,
      skill_1_cooldown_left: skill_1_cooldown_left,
      skill_2_cooldown_left: skill_2_cooldown_left,
      skill_3_cooldown_left: skill_3_cooldown_left,
      skill_4_cooldown_left: skill_4_cooldown_left,
      character_name: name,
      effects: effects,
      direction: direction,
      body_size: body_size,
      inventory: inventory,
      available_burst_loads: available_burst_loads
    }
  end

  def decode(%ProtoProjectile{} = projectile, ProtoProjectile) do
    %{
      id: id,
      position: position,
      direction: direction,
      speed: speed,
      range: range,
      player_id: player_id,
      damage: damage,
      remaining_ticks: remaining_ticks,
      projectile_type: projectile_type,
      status: status,
      last_attacked_player_id: last_attacked_player_id,
      pierce: pierce,
      skill_name: skill_name
    } = projectile

    %GameProjectile{
      id: id,
      position: position,
      direction: direction,
      speed: speed,
      range: range,
      player_id: player_id,
      damage: damage,
      remaining_ticks: remaining_ticks,
      projectile_type: projectile_decode(projectile_type),
      status: projectile_status_decode(status),
      last_attacked_player_id: last_attacked_player_id,
      pierce: pierce,
      skill_name: skill_name
    }
  end

  def decode(%struct{} = msg, struct) do
    Map.from_struct(msg)
  end

  ###############################
  # Helpers for transformations #
  ###############################
  defp player_action_enum_encode(:nothing), do: :PLAYER_ACTION_ENUM_NOTHING
  defp player_action_enum_encode(:moving), do: :PLAYER_ACTION_ENUM_MOVING
  defp player_action_enum_encode(:using_skill), do: :PLAYER_ACTION_ENUM_USING_SKILL

  defp player_status_encode(:alive), do: :PLAYER_STATUS_ALIVE
  defp player_status_encode(:death), do: :PLAYER_STATUS_DEAD

  defp kill_entity_encode(:player), do: :KILL_ENTITY_PLAYER
  defp kill_entity_encode(:loot), do: :KILL_ENTITY_ITEM
  defp kill_entity_encode(:zone), do: :KILL_ENTITY_ZONE

  defp player_old_status_encode(:alive), do: :ALIVE
  defp player_old_status_encode(:dead), do: :DEAD

  defp player_old_status_decode(:ALIVE), do: :alive
  defp player_old_status_decode(:DEAD), do: :dead

  def player_action_encode([]), do: []

  def player_action_encode([%{action: :attacking, duration: duration} | tail]),
    do: [%{player_action: :ATTACKING, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :nothing} | tail]), do: player_action_encode(tail)

  def player_action_encode([%{action: :attackingaoe, duration: duration} | tail]),
    do: [%{player_action: :ATTACKING_AOE, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :startingskill1, duration: duration} | tail]),
    do: [%{player_action: :STARTING_SKILL_1, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :startingskill2, duration: duration} | tail]),
    do: [%{player_action: :STARTING_SKILL_2, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :startingskill3, duration: duration} | tail]),
    do: [%{player_action: :STARTING_SKILL_3, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :startingskill4, duration: duration} | tail]),
    do: [%{player_action: :STARTING_SKILL_4, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :executingskill1, duration: duration} | tail]),
    do: [%{player_action: :EXECUTING_SKILL_1, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :executingskill2, duration: duration} | tail]),
    do: [%{player_action: :EXECUTING_SKILL_2, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :executingskill3, duration: duration} | tail]),
    do: [%{player_action: :EXECUTING_SKILL_3, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :executingskill4, duration: duration} | tail]),
    do: [%{player_action: :EXECUTING_SKILL_4, duration: duration} | player_action_encode(tail)]

  def player_action_encode([%{action: :moving, duration: duration} | tail]),
    do: [%{player_action: :MOVING, duration: duration} | player_action_encode(tail)]

  defp player_action_decode([]), do: []
  defp player_action_decode([%{player_action: :ATTACKING} | tail]), do: [:attacking, player_action_decode(tail)]
  defp player_action_decode([%{player_action: :NOTHING} | tail]), do: player_action_decode(tail)
  defp player_action_decode([%{player_action: :ATTACKING_AOE} | tail]), do: [:attackingaoe, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :STARTING_SKILL_1} | tail]),
    do: [:startingskill1, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :STARTING_SKILL_2} | tail]),
    do: [:startingskill2, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :STARTING_SKILL_3} | tail]),
    do: [:startingskill3, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :STARTING_SKILL_4} | tail]),
    do: [:startingskill4, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :EXECUTING_SKILL_1} | tail]),
    do: [:executingskill1, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :EXECUTING_SKILL_2} | tail]),
    do: [:executingskill2, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :EXECUTING_SKILL_3} | tail]),
    do: [:executingskill3, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :EXECUTING_SKILL_4} | tail]),
    do: [:executingskill4, player_action_decode(tail)]

  defp player_action_decode([%{player_action: :MOVING} | tail]), do: [:moving, player_action_decode(tail)]

  defp projectile_encode(:bullet), do: :BULLET
  defp projectile_encode(:disarmingbullet), do: :DISARMING_BULLET
  defp projectile_decode(:BULLET), do: :bullet
  defp projectile_decode(:DISARMING_BULLET), do: :disarmingbullet

  defp projectile_status_encode(:active), do: :ACTIVE
  defp projectile_status_encode(:exploded), do: :EXPLODED

  defp projectile_status_decode(:ACTIVE), do: :active
  defp projectile_status_decode(:EXPLODED), do: :exploded

  defp loot_type_encode({:health, _}), do: :LOOT_HEALTH

  defp modifier_encode(:multiplicative), do: :MULTIPLICATIVE
  defp modifier_encode(:additive), do: :ADDITIVE

  defp mechanic_name_encode(:hit), do: :HIT
  defp mechanic_name_encode(:simple_shoot), do: :SIMPLE_SHOOT
  defp mechanic_name_encode(:multi_shoot), do: :MULTI_SHOOT
  defp mechanic_name_encode(:give_effect), do: :GIVE_EFFECT
  defp mechanic_name_encode(:move_to_target), do: :MOVE_TO_TARGET
end

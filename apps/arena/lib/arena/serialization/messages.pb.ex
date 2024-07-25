defmodule Arena.Serialization.GameStatusPB do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PREPARING, 0)
  field(:RUNNING, 1)
  field(:ENDED, 2)
  field(:SELECTING_BOUNTY, 3)
end

defmodule Arena.Serialization.ProjectileStatusPB do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:ACTIVE, 0)
  field(:EXPLODED, 1)
  field(:CONSUMED, 2)
end

defmodule Arena.Serialization.CrateStatusPB do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:FINE, 0)
  field(:DESTROYED, 1)
end

defmodule Arena.Serialization.PowerUpstatusPB do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:AVAILABLE, 0)
  field(:TAKEN, 1)
  field(:UNAVAILABLE, 2)
end

defmodule Arena.Serialization.PlayerActionTypePB do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:MOVING, 0)
  field(:STARTING_SKILL_1, 1)
  field(:STARTING_SKILL_2, 2)
  field(:EXECUTING_SKILL_1, 3)
  field(:EXECUTING_SKILL_2, 4)
  field(:EXECUTING_SKILL_3, 5)
end

defmodule Arena.Serialization.TrapStatusPB do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PENDING, 0)
  field(:PREPARED, 1)
  field(:TRIGGERED, 2)
  field(:USED, 3)
end

defmodule Arena.Serialization.PoolStatusPB do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:WAITING, 0)
  field(:READY, 1)
end

defmodule Arena.Serialization.DirectionPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule Arena.Serialization.PositionPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule Arena.Serialization.LobbyEventPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:leave, 1, type: Arena.Serialization.LeaveLobbyPB, oneof: 0)
  field(:left, 2, type: Arena.Serialization.LeftLobbyPB, oneof: 0)
  field(:joined, 3, type: Arena.Serialization.JoinedLobbyPB, oneof: 0)
  field(:game, 4, type: Arena.Serialization.GameStatePB, oneof: 0)
end

defmodule Arena.Serialization.LeaveLobbyPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule Arena.Serialization.LeftLobbyPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule Arena.Serialization.JoinedLobbyPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule Arena.Serialization.GameEventPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:joined, 1, type: Arena.Serialization.GameJoinedPB, oneof: 0)
  field(:update, 2, type: Arena.Serialization.GameStatePB, oneof: 0)
  field(:finished, 3, type: Arena.Serialization.GameFinishedPB, oneof: 0)
  field(:ping, 4, type: Arena.Serialization.PingUpdatePB, oneof: 0)
  field(:toggle_bots, 5, type: Arena.Serialization.ToggleBotsPB, json_name: "toggleBots", oneof: 0)
end

defmodule Arena.Serialization.GameFinishedPB.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameFinishedPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:winner, 1, type: Arena.Serialization.EntityPB)

  field(:players, 2,
    repeated: true,
    type: Arena.Serialization.GameFinishedPB.PlayersEntry,
    map: true
  )
end

defmodule Arena.Serialization.PingUpdatePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:latency, 1, type: :uint64)
end

defmodule Arena.Serialization.GameJoinedPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:config, 2, type: Arena.Serialization.ConfigurationPB)
  field(:bounties, 3, repeated: true, type: Arena.Serialization.BountyInfoPB)
end

defmodule Arena.Serialization.ConfigurationPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game, 1, type: Arena.Serialization.ConfigGamePB)
  field(:map, 2, type: Arena.Serialization.ConfigMapPB)
  field(:characters, 3, repeated: true, type: Arena.Serialization.ConfigCharacterPB)
  field(:client_config, 4, type: Arena.Serialization.ClientConfigPB, json_name: "clientConfig")
end

defmodule Arena.Serialization.ConfigGamePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:tick_rate_ms, 1, type: :float, json_name: "tickRateMs")
  field(:bounty_pick_time_ms, 2, type: :float, json_name: "bountyPickTimeMs")
  field(:start_game_time_ms, 3, type: :float, json_name: "startGameTimeMs")
end

defmodule Arena.Serialization.ConfigMapPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
end

defmodule Arena.Serialization.ConfigCharacterPB.SkillsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: Arena.Serialization.ConfigSkillPB)
end

defmodule Arena.Serialization.ConfigCharacterPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:active, 2, type: :bool)
  field(:base_speed, 3, type: :float, json_name: "baseSpeed")
  field(:base_size, 4, type: :float, json_name: "baseSize")
  field(:base_health, 5, type: :uint64, json_name: "baseHealth")
  field(:max_inventory_size, 6, type: :uint64, json_name: "maxInventorySize")

  field(:skills, 7,
    repeated: true,
    type: Arena.Serialization.ConfigCharacterPB.SkillsEntry,
    map: true
  )
end

defmodule Arena.Serialization.ClientConfigPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:server_update, 1,
    type: Arena.Serialization.ConfigServerUpdatePB,
    json_name: "serverUpdate"
  )
end

defmodule Arena.Serialization.ConfigServerUpdatePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:timestamp_difference_samples_to_check_warning, 1,
    type: :uint64,
    json_name: "timestampDifferenceSamplesToCheckWarning"
  )

  field(:timestamp_differences_samples_max_length, 2,
    type: :uint64,
    json_name: "timestampDifferencesSamplesMaxLength"
  )

  field(:show_warning_threshold, 3, type: :uint64, json_name: "showWarningThreshold")
  field(:stop_warning_threshold, 4, type: :uint64, json_name: "stopWarningThreshold")
  field(:ms_without_update_show_warning, 5, type: :uint64, json_name: "msWithoutUpdateShowWarning")
  field(:ms_without_update_disconnect, 6, type: :uint64, json_name: "msWithoutUpdateDisconnect")
end

defmodule Arena.Serialization.ConfigSkillPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:cooldown_ms, 2, type: :uint64, json_name: "cooldownMs")
  field(:execution_duration_ms, 3, type: :uint64, json_name: "executionDurationMs")
  field(:targetting_radius, 4, type: :float, json_name: "targettingRadius")
  field(:targetting_angle, 5, type: :float, json_name: "targettingAngle")
  field(:targetting_range, 6, type: :float, json_name: "targettingRange")
  field(:stamina_cost, 7, type: :uint64, json_name: "staminaCost")
  field(:targetting_offset, 8, type: :float, json_name: "targettingOffset")
end

defmodule Arena.Serialization.GameStatePB.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB.ProjectilesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB.PlayerTimestampsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :int64)
end

defmodule Arena.Serialization.GameStatePB.DamageTakenEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule Arena.Serialization.GameStatePB.DamageDoneEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule Arena.Serialization.GameStatePB.PowerUpsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB.ItemsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB.ObstaclesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB.PoolsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB.CratesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB.BushesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB.TrapsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: Arena.Serialization.EntityPB)
end

defmodule Arena.Serialization.GameStatePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game_id, 1, type: :string, json_name: "gameId")
  field(:players, 2, repeated: true, type: Arena.Serialization.GameStatePB.PlayersEntry, map: true)

  field(:projectiles, 3,
    repeated: true,
    type: Arena.Serialization.GameStatePB.ProjectilesEntry,
    map: true
  )

  field(:player_timestamps, 4,
    repeated: true,
    type: Arena.Serialization.GameStatePB.PlayerTimestampsEntry,
    json_name: "playerTimestamps",
    map: true
  )

  field(:server_timestamp, 5, type: :int64, json_name: "serverTimestamp")
  field(:zone, 6, type: Arena.Serialization.ZonePB)
  field(:killfeed, 7, repeated: true, type: Arena.Serialization.KillEntryPB)

  field(:damage_taken, 8,
    repeated: true,
    type: Arena.Serialization.GameStatePB.DamageTakenEntry,
    json_name: "damageTaken",
    map: true
  )

  field(:damage_done, 9,
    repeated: true,
    type: Arena.Serialization.GameStatePB.DamageDoneEntry,
    json_name: "damageDone",
    map: true
  )

  field(:power_ups, 10,
    repeated: true,
    type: Arena.Serialization.GameStatePB.PowerUpsEntry,
    json_name: "powerUps",
    map: true
  )

  field(:status, 11, type: Arena.Serialization.GameStatusPB, enum: true)
  field(:start_game_timestamp, 12, type: :int64, json_name: "startGameTimestamp")
  field(:items, 13, repeated: true, type: Arena.Serialization.GameStatePB.ItemsEntry, map: true)

  field(:obstacles, 14,
    repeated: true,
    type: Arena.Serialization.GameStatePB.ObstaclesEntry,
    map: true
  )

  field(:pools, 15, repeated: true, type: Arena.Serialization.GameStatePB.PoolsEntry, map: true)
  field(:crates, 16, repeated: true, type: Arena.Serialization.GameStatePB.CratesEntry, map: true)
  field(:bushes, 17, repeated: true, type: Arena.Serialization.GameStatePB.BushesEntry, map: true)
  field(:traps, 18, repeated: true, type: Arena.Serialization.GameStatePB.TrapsEntry, map: true)
end

defmodule Arena.Serialization.EntityPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:aditional_info, 0)

  field(:id, 1, type: :uint64)
  field(:category, 2, type: :string)
  field(:shape, 3, type: :string)
  field(:name, 4, type: :string)
  field(:position, 5, type: Arena.Serialization.PositionPB)
  field(:radius, 6, type: :float)
  field(:vertices, 7, repeated: true, type: Arena.Serialization.PositionPB)
  field(:collides_with, 8, repeated: true, type: :uint64, json_name: "collidesWith")
  field(:speed, 9, type: :float)
  field(:direction, 10, type: Arena.Serialization.DirectionPB)
  field(:is_moving, 11, type: :bool, json_name: "isMoving")
  field(:player, 12, type: Arena.Serialization.PlayerPB, oneof: 0)
  field(:projectile, 13, type: Arena.Serialization.ProjectilePB, oneof: 0)
  field(:obstacle, 14, type: Arena.Serialization.ObstaclePB, oneof: 0)
  field(:power_up, 15, type: Arena.Serialization.PowerUpPB, json_name: "powerUp", oneof: 0)
  field(:item, 16, type: Arena.Serialization.ItemPB, oneof: 0)
  field(:pool, 17, type: Arena.Serialization.PoolPB, oneof: 0)
  field(:crate, 18, type: Arena.Serialization.CratePB, oneof: 0)
  field(:bush, 19, type: Arena.Serialization.BushPB, oneof: 0)
  field(:trap, 20, type: Arena.Serialization.TrapPB, oneof: 0)
end

defmodule Arena.Serialization.PlayerPB.CooldownsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :uint64)
end

defmodule Arena.Serialization.PlayerPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:health, 1, type: :uint64)
  field(:kill_count, 2, type: :uint64, json_name: "killCount")

  field(:current_actions, 3,
    repeated: true,
    type: Arena.Serialization.PlayerActionPB,
    json_name: "currentActions"
  )

  field(:available_stamina, 4, type: :uint64, json_name: "availableStamina")
  field(:max_stamina, 5, type: :uint64, json_name: "maxStamina")
  field(:stamina_interval, 6, type: :uint64, json_name: "staminaInterval")
  field(:recharging_stamina, 7, type: :bool, json_name: "rechargingStamina")
  field(:character_name, 8, type: :string, json_name: "characterName")
  field(:power_ups, 9, type: :uint64, json_name: "powerUps")
  field(:effects, 10, repeated: true, type: Arena.Serialization.EffectPB)
  field(:inventory, 11, type: Arena.Serialization.ItemPB)

  field(:cooldowns, 12,
    repeated: true,
    type: Arena.Serialization.PlayerPB.CooldownsEntry,
    map: true
  )

  field(:visible_players, 13, repeated: true, type: :uint64, json_name: "visiblePlayers")
  field(:on_bush, 14, type: :bool, json_name: "onBush")
  field(:forced_movement, 15, type: :bool, json_name: "forcedMovement")
  field(:bounty_completed, 16, type: :bool, json_name: "bountyCompleted")
end

defmodule Arena.Serialization.EffectPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:duration_ms, 2, type: :uint32, json_name: "durationMs")
  field(:id, 3, type: :uint64)
end

defmodule Arena.Serialization.ItemPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 2, type: :string)
end

defmodule Arena.Serialization.ProjectilePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:damage, 1, type: :uint64)
  field(:owner_id, 2, type: :uint64, json_name: "ownerId")
  field(:status, 3, type: Arena.Serialization.ProjectileStatusPB, enum: true)
  field(:skill_key, 4, type: :string, json_name: "skillKey")
end

defmodule Arena.Serialization.ObstaclePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:color, 1, type: :string)
  field(:collisionable, 2, type: :bool)
  field(:status, 3, type: :string)
end

defmodule Arena.Serialization.PowerUpPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:status, 2, type: Arena.Serialization.PowerUpstatusPB, enum: true)
end

defmodule Arena.Serialization.CratePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:health, 1, type: :uint64)
  field(:amount_of_power_ups, 2, type: :uint64, json_name: "amountOfPowerUps")
  field(:status, 3, type: Arena.Serialization.CrateStatusPB, enum: true)
end

defmodule Arena.Serialization.PoolPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:status, 2, type: Arena.Serialization.PoolStatusPB, enum: true)
  field(:effects, 3, repeated: true, type: Arena.Serialization.EffectPB)
  field(:skill_key, 4, type: :string, json_name: "skillKey")
end

defmodule Arena.Serialization.BushPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule Arena.Serialization.TrapPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:name, 2, type: :string)
  field(:status, 3, type: Arena.Serialization.TrapStatusPB, enum: true)
end

defmodule Arena.Serialization.PlayerActionPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:action, 1, type: Arena.Serialization.PlayerActionTypePB, enum: true)
  field(:duration, 2, type: :uint64)
  field(:destination, 3, type: Arena.Serialization.PositionPB)
  field(:direction, 4, type: Arena.Serialization.PositionPB)
end

defmodule Arena.Serialization.MovePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:direction, 1, type: Arena.Serialization.DirectionPB)
end

defmodule Arena.Serialization.AttackPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:skill, 1, type: :string)
  field(:parameters, 2, type: Arena.Serialization.AttackParametersPB)
end

defmodule Arena.Serialization.AttackParametersPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:target, 1, type: Arena.Serialization.DirectionPB)
end

defmodule Arena.Serialization.UseItemPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:item, 1, type: :uint64)
end

defmodule Arena.Serialization.SelectBountyPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:bounty_quest_id, 1, type: :string, json_name: "bountyQuestId")
end

defmodule Arena.Serialization.ToggleZonePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:active, 1, type: :bool)
end

defmodule Arena.Serialization.ToggleBotsPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:active, 1, type: :bool)
end

defmodule Arena.Serialization.ChangeTickratePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:tickrate, 1, type: :int64)
end

defmodule Arena.Serialization.GameActionPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field(:move, 1, type: Arena.Serialization.MovePB, oneof: 0)
  field(:attack, 2, type: Arena.Serialization.AttackPB, oneof: 0)
  field(:use_item, 4, type: Arena.Serialization.UseItemPB, json_name: "useItem", oneof: 0)

  field(:select_bounty, 5,
    type: Arena.Serialization.SelectBountyPB,
    json_name: "selectBounty",
    oneof: 0
  )

  field(:toggle_zone, 6, type: Arena.Serialization.ToggleZonePB, json_name: "toggleZone", oneof: 0)
  field(:toggle_bots, 7, type: Arena.Serialization.ToggleBotsPB, json_name: "toggleBots", oneof: 0)

  field(:change_tickrate, 8,
    type: Arena.Serialization.ChangeTickratePB,
    json_name: "changeTickrate",
    oneof: 0
  )

  field(:timestamp, 3, type: :int64)
end

defmodule Arena.Serialization.ZonePB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
  field(:enabled, 2, type: :bool)
  field(:next_zone_change_timestamp, 3, type: :int64, json_name: "nextZoneChangeTimestamp")
  field(:shrinking, 4, type: :bool)
end

defmodule Arena.Serialization.KillEntryPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:killer_id, 1, type: :uint64, json_name: "killerId")
  field(:victim_id, 2, type: :uint64, json_name: "victimId")
end

defmodule Arena.Serialization.BountyInfoPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :string)
  field(:description, 2, type: :string)
  field(:quest_type, 3, type: :string, json_name: "questType")
  field(:reward, 4, type: Arena.Serialization.CurrencyRewardPB)
end

defmodule Arena.Serialization.CurrencyRewardPB do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:currency, 1, type: :string)
  field(:amount, 2, type: :int64)
end

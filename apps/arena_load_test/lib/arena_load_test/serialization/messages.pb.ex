defmodule ArenaLoadTest.Serialization.GameStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PREPARING, 0)
  field(:RUNNING, 1)
  field(:ENDED, 2)
end

defmodule ArenaLoadTest.Serialization.ProjectileStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:ACTIVE, 0)
  field(:EXPLODED, 1)
end

defmodule ArenaLoadTest.Serialization.PowerUpstatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:AVAILABLE, 0)
  field(:TAKEN, 1)
end

defmodule ArenaLoadTest.Serialization.PlayerActionType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:MOVING, 0)
  field(:STARTING_SKILL_1, 1)
  field(:STARTING_SKILL_2, 2)
  field(:EXECUTING_SKILL_1, 3)
  field(:EXECUTING_SKILL_2, 4)
  field(:EXECUTING_SKILL_3, 5)
end

defmodule ArenaLoadTest.Serialization.Direction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule ArenaLoadTest.Serialization.Position do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule ArenaLoadTest.Serialization.GameEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:joined, 1, type: ArenaLoadTest.Serialization.GameJoined, oneof: 0)
  field(:update, 2, type: ArenaLoadTest.Serialization.GameState, oneof: 0)
  field(:finished, 3, type: ArenaLoadTest.Serialization.GameFinished, oneof: 0)
  field(:ping, 4, type: ArenaLoadTest.Serialization.PingUpdate, oneof: 0)
end

defmodule ArenaLoadTest.Serialization.GameFinished.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameFinished do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:winner, 1, type: ArenaLoadTest.Serialization.Entity)

  field(:players, 2,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameFinished.PlayersEntry,
    map: true
  )
end

defmodule ArenaLoadTest.Serialization.PingUpdate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:latency, 1, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.GameJoined do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:config, 2, type: ArenaLoadTest.Serialization.Configuration)
end

defmodule ArenaLoadTest.Serialization.Configuration do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game, 1, type: ArenaLoadTest.Serialization.ConfigGame)
  field(:map, 2, type: ArenaLoadTest.Serialization.ConfigMap)
  field(:characters, 3, repeated: true, type: ArenaLoadTest.Serialization.ConfigCharacter)
end

defmodule ArenaLoadTest.Serialization.ConfigGame do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:tick_rate_ms, 1, type: :float, json_name: "tickRateMs")
end

defmodule ArenaLoadTest.Serialization.ConfigMap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
end

defmodule ArenaLoadTest.Serialization.ConfigCharacter.SkillsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: ArenaLoadTest.Serialization.ConfigSkill)
end

defmodule ArenaLoadTest.Serialization.ConfigCharacter do
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
    type: ArenaLoadTest.Serialization.ConfigCharacter.SkillsEntry,
    map: true
  )
end

defmodule ArenaLoadTest.Serialization.ConfigSkill do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:cooldown_ms, 2, type: :uint64, json_name: "cooldownMs")
  field(:execution_duration_ms, 3, type: :uint64, json_name: "executionDurationMs")
  field(:targetting_radius, 4, type: :float, json_name: "targettingRadius")
  field(:targetting_angle, 5, type: :float, json_name: "targettingAngle")
  field(:targetting_range, 6, type: :float, json_name: "targettingRange")
  field(:stamina_cost, 7, type: :uint64, json_name: "staminaCost")
end

defmodule ArenaLoadTest.Serialization.GameState.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.ProjectilesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.PlayerTimestampsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :int64)
end

defmodule ArenaLoadTest.Serialization.GameState.DamageTakenEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.GameState.DamageDoneEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.GameState.PowerUpsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.ItemsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.PoolsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game_id, 1, type: :string, json_name: "gameId")

  field(:players, 2,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.PlayersEntry,
    map: true
  )

  field(:projectiles, 3,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.ProjectilesEntry,
    map: true
  )

  field(:player_timestamps, 4,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.PlayerTimestampsEntry,
    json_name: "playerTimestamps",
    map: true
  )

  field(:server_timestamp, 5, type: :int64, json_name: "serverTimestamp")
  field(:zone, 6, type: ArenaLoadTest.Serialization.Zone)
  field(:killfeed, 7, repeated: true, type: ArenaLoadTest.Serialization.KillEntry)

  field(:damage_taken, 8,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.DamageTakenEntry,
    json_name: "damageTaken",
    map: true
  )

  field(:damage_done, 9,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.DamageDoneEntry,
    json_name: "damageDone",
    map: true
  )

  field(:power_ups, 10,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.PowerUpsEntry,
    json_name: "powerUps",
    map: true
  )

  field(:status, 11, type: ArenaLoadTest.Serialization.GameStatus, enum: true)
  field(:start_game_timestamp, 12, type: :int64, json_name: "startGameTimestamp")

  field(:items, 13,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.ItemsEntry,
    map: true
  )

  field(:pools, 14,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.PoolsEntry,
    map: true
  )
end

defmodule ArenaLoadTest.Serialization.Entity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:aditional_info, 0)

  field(:id, 1, type: :uint64)
  field(:category, 2, type: :string)
  field(:shape, 3, type: :string)
  field(:name, 4, type: :string)
  field(:position, 5, type: ArenaLoadTest.Serialization.Position)
  field(:radius, 6, type: :float)
  field(:vertices, 7, repeated: true, type: ArenaLoadTest.Serialization.Position)
  field(:collides_with, 8, repeated: true, type: :uint64, json_name: "collidesWith")
  field(:speed, 9, type: :float)
  field(:direction, 10, type: ArenaLoadTest.Serialization.Direction)
  field(:is_moving, 11, type: :bool, json_name: "isMoving")
  field(:player, 12, type: ArenaLoadTest.Serialization.Player, oneof: 0)
  field(:projectile, 13, type: ArenaLoadTest.Serialization.Projectile, oneof: 0)
  field(:obstacle, 14, type: ArenaLoadTest.Serialization.Obstacle, oneof: 0)
  field(:power_up, 15, type: ArenaLoadTest.Serialization.PowerUp, json_name: "powerUp", oneof: 0)
  field(:item, 16, type: ArenaLoadTest.Serialization.Item, oneof: 0)
  field(:pool, 17, type: ArenaLoadTest.Serialization.Pool, oneof: 0)
end

defmodule ArenaLoadTest.Serialization.Player.EffectsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Effect)
end

defmodule ArenaLoadTest.Serialization.Player.CooldownsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.Player do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:health, 1, type: :uint64)
  field(:kill_count, 2, type: :uint64, json_name: "killCount")

  field(:current_actions, 3,
    repeated: true,
    type: ArenaLoadTest.Serialization.PlayerAction,
    json_name: "currentActions"
  )

  field(:available_stamina, 4, type: :uint64, json_name: "availableStamina")
  field(:max_stamina, 5, type: :uint64, json_name: "maxStamina")
  field(:stamina_interval, 6, type: :uint64, json_name: "staminaInterval")
  field(:recharging_stamina, 7, type: :bool, json_name: "rechargingStamina")
  field(:character_name, 8, type: :string, json_name: "characterName")
  field(:power_ups, 9, type: :uint64, json_name: "powerUps")

  field(:effects, 10,
    repeated: true,
    type: ArenaLoadTest.Serialization.Player.EffectsEntry,
    map: true
  )

  field(:inventory, 11, type: ArenaLoadTest.Serialization.Item)

  field(:cooldowns, 12,
    repeated: true,
    type: ArenaLoadTest.Serialization.Player.CooldownsEntry,
    map: true
  )
end

defmodule ArenaLoadTest.Serialization.Effect do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:duration_ms, 2, type: :uint32, json_name: "durationMs")
end

defmodule ArenaLoadTest.Serialization.Item do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 2, type: :string)
end

defmodule ArenaLoadTest.Serialization.Projectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:damage, 1, type: :uint64)
  field(:owner_id, 2, type: :uint64, json_name: "ownerId")
  field(:status, 3, type: ArenaLoadTest.Serialization.ProjectileStatus, enum: true)
  field(:skill_key, 4, type: :string, json_name: "skillKey")
end

defmodule ArenaLoadTest.Serialization.Obstacle do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:color, 1, type: :string)
end

defmodule ArenaLoadTest.Serialization.PowerUp do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:status, 2, type: ArenaLoadTest.Serialization.PowerUpstatus, enum: true)
end

defmodule ArenaLoadTest.Serialization.Pool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
end

defmodule ArenaLoadTest.Serialization.PlayerAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:action, 1, type: ArenaLoadTest.Serialization.PlayerActionType, enum: true)
  field(:duration, 2, type: :uint64)
  field(:destination, 3, type: ArenaLoadTest.Serialization.Position)
end

defmodule ArenaLoadTest.Serialization.Move do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:direction, 1, type: ArenaLoadTest.Serialization.Direction)
end

defmodule ArenaLoadTest.Serialization.Attack do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:skill, 1, type: :string)
  field(:parameters, 2, type: ArenaLoadTest.Serialization.AttackParameters)
end

defmodule ArenaLoadTest.Serialization.AttackParameters do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:target, 1, type: ArenaLoadTest.Serialization.Direction)
end

defmodule ArenaLoadTest.Serialization.UseItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:item, 1, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.GameAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field(:move, 1, type: ArenaLoadTest.Serialization.Move, oneof: 0)
  field(:attack, 2, type: ArenaLoadTest.Serialization.Attack, oneof: 0)
  field(:use_item, 4, type: ArenaLoadTest.Serialization.UseItem, json_name: "useItem", oneof: 0)
  field(:timestamp, 3, type: :int64)
end

defmodule ArenaLoadTest.Serialization.Zone do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
  field(:enabled, 2, type: :bool)
  field(:next_zone_change_timestamp, 3, type: :int64, json_name: "nextZoneChangeTimestamp")
  field(:shrinking, 4, type: :bool)
end

defmodule ArenaLoadTest.Serialization.KillEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:killer_id, 1, type: :uint64, json_name: "killerId")
  field(:victim_id, 2, type: :uint64, json_name: "victimId")
end

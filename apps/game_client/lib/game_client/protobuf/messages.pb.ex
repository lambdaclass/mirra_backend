defmodule GameClient.Protobuf.GameStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PREPARING, 0)
  field(:RUNNING, 1)
  field(:ENDED, 2)
  field(:SELECTING_BOUNTY, 3)
end

defmodule GameClient.Protobuf.ProjectileStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:ACTIVE, 0)
  field(:EXPLODED, 1)
  field(:CONSUMED, 2)
end

defmodule GameClient.Protobuf.ProtoCrateStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:FINE, 0)
  field(:DESTROYED, 1)
end

defmodule GameClient.Protobuf.ProtoPowerUpstatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:AVAILABLE, 0)
  field(:TAKEN, 1)
  field(:UNAVAILABLE, 2)
end

defmodule GameClient.Protobuf.ProtoPlayerActionType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:MOVING, 0)
  field(:STARTING_SKILL_1, 1)
  field(:STARTING_SKILL_2, 2)
  field(:EXECUTING_SKILL_1, 3)
  field(:EXECUTING_SKILL_2, 4)
  field(:EXECUTING_SKILL_3, 5)
end

defmodule GameClient.Protobuf.ProtoTrapStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PENDING, 0)
  field(:PREPARED, 1)
  field(:TRIGGERED, 2)
  field(:USED, 3)
end

defmodule GameClient.Protobuf.ProtoPoolStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:WAITING, 0)
  field(:READY, 1)
end

defmodule GameClient.Protobuf.ProtoDirection do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule GameClient.Protobuf.ProtoPosition do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule GameClient.Protobuf.ProtoLobbyEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:leave, 1, type: GameClient.Protobuf.ProtoLeaveLobby, oneof: 0)
  field(:left, 2, type: GameClient.Protobuf.ProtoLeftLobby, oneof: 0)
  field(:joined, 3, type: GameClient.Protobuf.ProtoJoinedLobby, oneof: 0)
  field(:game, 4, type: GameClient.Protobuf.ProtoGameState, oneof: 0)
end

defmodule GameClient.Protobuf.ProtoLeaveLobby do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.ProtoLeftLobby do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.ProtoJoinedLobby do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.ProtoGameEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:joined, 1, type: GameClient.Protobuf.ProtoGameJoined, oneof: 0)
  field(:update, 2, type: GameClient.Protobuf.ProtoGameState, oneof: 0)
  field(:finished, 3, type: GameClient.Protobuf.ProtoGameFinished, oneof: 0)
  field(:ping, 4, type: GameClient.Protobuf.ProtoPingUpdate, oneof: 0)

  field(:toggle_bots, 5,
    type: GameClient.Protobuf.ProtoToggleBots,
    json_name: "toggleBots",
    oneof: 0
  )
end

defmodule GameClient.Protobuf.ProtoGameFinished.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameFinished do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:winner, 1, type: GameClient.Protobuf.ProtoEntity)

  field(:players, 2,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameFinished.PlayersEntry,
    map: true
  )
end

defmodule GameClient.Protobuf.ProtoPingUpdate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:latency, 1, type: :uint64)
end

defmodule GameClient.Protobuf.ProtoGameJoined do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:config, 2, type: GameClient.Protobuf.ProtoConfiguration)
  field(:bounties, 3, repeated: true, type: GameClient.Protobuf.ProtoBountyInfo)
end

defmodule GameClient.Protobuf.ProtoConfiguration do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game, 1, type: GameClient.Protobuf.ProtoConfigGame)
  field(:map, 2, type: GameClient.Protobuf.ProtoConfigMap)
  field(:characters, 3, repeated: true, type: GameClient.Protobuf.ProtoConfigCharacter)
  field(:client_config, 4, type: GameClient.Protobuf.ProtoClientConfig, json_name: "clientConfig")
end

defmodule GameClient.Protobuf.ProtoConfigGame do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:tick_rate_ms, 1, type: :float, json_name: "tickRateMs")
  field(:bounty_pick_time_ms, 2, type: :float, json_name: "bountyPickTimeMs")
  field(:start_game_time_ms, 3, type: :float, json_name: "startGameTimeMs")
end

defmodule GameClient.Protobuf.ProtoConfigMap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
end

defmodule GameClient.Protobuf.ProtoConfigCharacter.SkillsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: GameClient.Protobuf.ProtoConfigSkill)
end

defmodule GameClient.Protobuf.ProtoConfigCharacter do
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
    type: GameClient.Protobuf.ProtoConfigCharacter.SkillsEntry,
    map: true
  )
end

defmodule GameClient.Protobuf.ProtoClientConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:server_update, 1,
    type: GameClient.Protobuf.ProtoConfigServerUpdate,
    json_name: "serverUpdate"
  )
end

defmodule GameClient.Protobuf.ProtoConfigServerUpdate do
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

defmodule GameClient.Protobuf.ProtoConfigSkill do
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

defmodule GameClient.Protobuf.ProtoGameState.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState.ProjectilesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState.PlayerTimestampsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :int64)
end

defmodule GameClient.Protobuf.ProtoGameState.DamageTakenEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule GameClient.Protobuf.ProtoGameState.DamageDoneEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule GameClient.Protobuf.ProtoGameState.PowerUpsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState.ItemsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState.ObstaclesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState.PoolsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState.CratesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState.BushesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState.TrapsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.ProtoEntity)
end

defmodule GameClient.Protobuf.ProtoGameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game_id, 1, type: :string, json_name: "gameId")

  field(:players, 2,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.PlayersEntry,
    map: true
  )

  field(:projectiles, 3,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.ProjectilesEntry,
    map: true
  )

  field(:player_timestamps, 4,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.PlayerTimestampsEntry,
    json_name: "playerTimestamps",
    map: true
  )

  field(:server_timestamp, 5, type: :int64, json_name: "serverTimestamp")
  field(:zone, 6, type: GameClient.Protobuf.ProtoZone)
  field(:killfeed, 7, repeated: true, type: GameClient.Protobuf.ProtoKillEntry)

  field(:damage_taken, 8,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.DamageTakenEntry,
    json_name: "damageTaken",
    map: true
  )

  field(:damage_done, 9,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.DamageDoneEntry,
    json_name: "damageDone",
    map: true
  )

  field(:power_ups, 10,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.PowerUpsEntry,
    json_name: "powerUps",
    map: true
  )

  field(:status, 11, type: GameClient.Protobuf.GameStatus, enum: true)
  field(:start_game_timestamp, 12, type: :int64, json_name: "startGameTimestamp")
  field(:items, 13, repeated: true, type: GameClient.Protobuf.ProtoGameState.ItemsEntry, map: true)

  field(:obstacles, 14,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.ObstaclesEntry,
    map: true
  )

  field(:pools, 15, repeated: true, type: GameClient.Protobuf.ProtoGameState.PoolsEntry, map: true)

  field(:crates, 16,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.CratesEntry,
    map: true
  )

  field(:bushes, 17,
    repeated: true,
    type: GameClient.Protobuf.ProtoGameState.BushesEntry,
    map: true
  )

  field(:traps, 18, repeated: true, type: GameClient.Protobuf.ProtoGameState.TrapsEntry, map: true)
end

defmodule GameClient.Protobuf.ProtoEntity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:aditional_info, 0)

  field(:id, 1, type: :uint64)
  field(:category, 2, type: :string)
  field(:shape, 3, type: :string)
  field(:name, 4, type: :string)
  field(:position, 5, type: GameClient.Protobuf.ProtoPosition)
  field(:radius, 6, type: :float)
  field(:vertices, 7, repeated: true, type: GameClient.Protobuf.ProtoPosition)
  field(:collides_with, 8, repeated: true, type: :uint64, json_name: "collidesWith")
  field(:speed, 9, type: :float)
  field(:direction, 10, type: GameClient.Protobuf.ProtoDirection)
  field(:is_moving, 11, type: :bool, json_name: "isMoving")
  field(:player, 12, type: GameClient.Protobuf.ProtoPlayer, oneof: 0)
  field(:projectile, 13, type: GameClient.Protobuf.ProtoProjectile, oneof: 0)
  field(:obstacle, 14, type: GameClient.Protobuf.ProtoObstacle, oneof: 0)
  field(:power_up, 15, type: GameClient.Protobuf.ProtoPowerUp, json_name: "powerUp", oneof: 0)
  field(:item, 16, type: GameClient.Protobuf.ProtoItem, oneof: 0)
  field(:pool, 17, type: GameClient.Protobuf.ProtoPool, oneof: 0)
  field(:crate, 18, type: GameClient.Protobuf.ProtoCrate, oneof: 0)
  field(:bush, 19, type: GameClient.Protobuf.ProtoBush, oneof: 0)
  field(:trap, 20, type: GameClient.Protobuf.ProtoTrap, oneof: 0)
end

defmodule GameClient.Protobuf.ProtoPlayer.CooldownsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :uint64)
end

defmodule GameClient.Protobuf.ProtoPlayer do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:health, 1, type: :uint64)
  field(:kill_count, 2, type: :uint64, json_name: "killCount")

  field(:current_actions, 3,
    repeated: true,
    type: GameClient.Protobuf.ProtoPlayerAction,
    json_name: "currentActions"
  )

  field(:available_stamina, 4, type: :uint64, json_name: "availableStamina")
  field(:max_stamina, 5, type: :uint64, json_name: "maxStamina")
  field(:stamina_interval, 6, type: :uint64, json_name: "staminaInterval")
  field(:recharging_stamina, 7, type: :bool, json_name: "rechargingStamina")
  field(:character_name, 8, type: :string, json_name: "characterName")
  field(:power_ups, 9, type: :uint64, json_name: "powerUps")
  field(:effects, 10, repeated: true, type: GameClient.Protobuf.ProtoEffect)
  field(:inventory, 11, type: GameClient.Protobuf.ProtoItem)

  field(:cooldowns, 12,
    repeated: true,
    type: GameClient.Protobuf.ProtoPlayer.CooldownsEntry,
    map: true
  )

  field(:visible_players, 13, repeated: true, type: :uint64, json_name: "visiblePlayers")
  field(:on_bush, 14, type: :bool, json_name: "onBush")
  field(:forced_movement, 15, type: :bool, json_name: "forcedMovement")
end

defmodule GameClient.Protobuf.ProtoEffect do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:duration_ms, 2, type: :uint32, json_name: "durationMs")
  field(:id, 3, type: :uint64)
end

defmodule GameClient.Protobuf.ProtoItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 2, type: :string)
end

defmodule GameClient.Protobuf.ProtoProjectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:damage, 1, type: :uint64)
  field(:owner_id, 2, type: :uint64, json_name: "ownerId")
  field(:status, 3, type: GameClient.Protobuf.ProjectileStatus, enum: true)
  field(:skill_key, 4, type: :string, json_name: "skillKey")
end

defmodule GameClient.Protobuf.ProtoObstacle do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:color, 1, type: :string)
  field(:collisionable, 2, type: :bool)
  field(:status, 3, type: :string)
end

defmodule GameClient.Protobuf.ProtoPowerUp do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:status, 2, type: GameClient.Protobuf.ProtoPowerUpstatus, enum: true)
end

defmodule GameClient.Protobuf.ProtoCrate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:health, 1, type: :uint64)
  field(:amount_of_power_ups, 2, type: :uint64, json_name: "amountOfPowerUps")
  field(:status, 3, type: GameClient.Protobuf.ProtoCrateStatus, enum: true)
end

defmodule GameClient.Protobuf.ProtoPool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:status, 2, type: GameClient.Protobuf.ProtoPoolStatus, enum: true)
  field(:effects, 3, repeated: true, type: GameClient.Protobuf.ProtoEffect)
  field(:skill_key, 4, type: :string, json_name: "skillKey")
end

defmodule GameClient.Protobuf.ProtoBush do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.ProtoTrap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:name, 2, type: :string)
  field(:status, 3, type: GameClient.Protobuf.ProtoTrapStatus, enum: true)
end

defmodule GameClient.Protobuf.ProtoPlayerAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:action, 1, type: GameClient.Protobuf.ProtoPlayerActionType, enum: true)
  field(:duration, 2, type: :uint64)
  field(:destination, 3, type: GameClient.Protobuf.ProtoPosition)
  field(:direction, 4, type: GameClient.Protobuf.ProtoPosition)
end

defmodule GameClient.Protobuf.ProtoMove do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:direction, 1, type: GameClient.Protobuf.ProtoDirection)
end

defmodule GameClient.Protobuf.ProtoAttack do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:skill, 1, type: :string)
  field(:parameters, 2, type: GameClient.Protobuf.ProtoAttackParameters)
end

defmodule GameClient.Protobuf.ProtoAttackParameters do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:target, 1, type: GameClient.Protobuf.ProtoDirection)
end

defmodule GameClient.Protobuf.ProtoUseItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:item, 1, type: :uint64)
end

defmodule GameClient.Protobuf.ProtoSelectBounty do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:bounty_quest_id, 1, type: :string, json_name: "bountyQuestId")
end

defmodule GameClient.Protobuf.ProtoToggleZone do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.ProtoToggleBots do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.ProtoChangeTickrate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:tickrate, 1, type: :int64)
end

defmodule GameClient.Protobuf.ProtoGameAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field(:move, 1, type: GameClient.Protobuf.ProtoMove, oneof: 0)
  field(:attack, 2, type: GameClient.Protobuf.ProtoAttack, oneof: 0)
  field(:use_item, 4, type: GameClient.Protobuf.ProtoUseItem, json_name: "useItem", oneof: 0)

  field(:select_bounty, 5,
    type: GameClient.Protobuf.ProtoSelectBounty,
    json_name: "selectBounty",
    oneof: 0
  )

  field(:toggle_zone, 6,
    type: GameClient.Protobuf.ProtoToggleZone,
    json_name: "toggleZone",
    oneof: 0
  )

  field(:toggle_bots, 7,
    type: GameClient.Protobuf.ProtoToggleBots,
    json_name: "toggleBots",
    oneof: 0
  )

  field(:change_tickrate, 8,
    type: GameClient.Protobuf.ProtoChangeTickrate,
    json_name: "changeTickrate",
    oneof: 0
  )

  field(:timestamp, 3, type: :int64)
end

defmodule GameClient.Protobuf.ProtoZone do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
  field(:enabled, 2, type: :bool)
  field(:next_zone_change_timestamp, 3, type: :int64, json_name: "nextZoneChangeTimestamp")
  field(:shrinking, 4, type: :bool)
end

defmodule GameClient.Protobuf.ProtoKillEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:killer_id, 1, type: :uint64, json_name: "killerId")
  field(:victim_id, 2, type: :uint64, json_name: "victimId")
end

defmodule GameClient.Protobuf.ProtoBountyInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :string)
  field(:description, 2, type: :string)
  field(:quest_type, 3, type: :string, json_name: "questType")
  field(:reward, 4, type: GameClient.Protobuf.ProtoCurrencyReward)
end

defmodule GameClient.Protobuf.ProtoCurrencyReward do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:currency, 1, type: :string)
  field(:amount, 2, type: :int64)
end

defmodule ArenaLoadTest.Serialization.GameMode do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:BATTLE, 0)
  field(:DEATHMATCH, 1)
  field(:DUO, 2)
  field(:QUICK_GAME, 3)
  field(:TRIO, 4)
end

defmodule ArenaLoadTest.Serialization.AttackType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:MELEE, 0)
  field(:RANGED, 1)
end

defmodule ArenaLoadTest.Serialization.SkillType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:BASIC, 0)
  field(:ULTIMATE, 1)
  field(:DASH, 2)
end

defmodule ArenaLoadTest.Serialization.GameStatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:PREPARING, 0)
  field(:RUNNING, 1)
  field(:ENDED, 2)
  field(:SELECTING_BOUNTY, 3)
end

defmodule ArenaLoadTest.Serialization.ItemStatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:ITEM_STATUS_UNDEFINED, 0)
  field(:ITEM_PICKED_UP, 1)
  field(:ITEM_USED, 2)
  field(:ITEM_ACTIVE, 3)
  field(:ITEM_EXPIRED, 4)
end

defmodule ArenaLoadTest.Serialization.ProjectileStatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:PROJECTILE_STATUS_UNDEFINED, 0)
  field(:ACTIVE, 1)
  field(:EXPLODED, 2)
  field(:CONSUMED, 3)
end

defmodule ArenaLoadTest.Serialization.CrateStatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:CRATE_STATUS_UNDEFINED, 0)
  field(:FINE, 1)
  field(:DESTROYED, 2)
end

defmodule ArenaLoadTest.Serialization.PowerUpstatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:AVAILABLE, 0)
  field(:TAKEN, 1)
  field(:UNAVAILABLE, 2)
end

defmodule ArenaLoadTest.Serialization.PlayerActionType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:MOVING, 0)
  field(:STARTING_SKILL_1, 1)
  field(:STARTING_SKILL_2, 2)
  field(:EXECUTING_SKILL_1, 3)
  field(:EXECUTING_SKILL_2, 4)
  field(:EXECUTING_SKILL_3, 5)
end

defmodule ArenaLoadTest.Serialization.TrapStatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:PENDING, 0)
  field(:PREPARED, 1)
  field(:TRIGGERED, 2)
  field(:USED, 3)
end

defmodule ArenaLoadTest.Serialization.PoolStatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:WAITING, 0)
  field(:READY, 1)
end

defmodule ArenaLoadTest.Serialization.Direction do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:x, 1, proto3_optional: true, type: :float)
  field(:y, 2, proto3_optional: true, type: :float)
end

defmodule ArenaLoadTest.Serialization.Position do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:x, 1, proto3_optional: true, type: :float)
  field(:y, 2, proto3_optional: true, type: :float)
end

defmodule ArenaLoadTest.Serialization.ListPositionPB do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:positions, 1, repeated: true, type: ArenaLoadTest.Serialization.Position)
end

defmodule ArenaLoadTest.Serialization.LobbyEvent do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  oneof(:event, 0)

  field(:leave, 1, type: ArenaLoadTest.Serialization.LeaveLobby, oneof: 0)
  field(:left, 2, type: ArenaLoadTest.Serialization.LeftLobby, oneof: 0)
  field(:joined, 3, type: ArenaLoadTest.Serialization.JoinedLobby, oneof: 0)
  field(:game, 4, type: ArenaLoadTest.Serialization.GameState, oneof: 0)
end

defmodule ArenaLoadTest.Serialization.LeaveLobby do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3
end

defmodule ArenaLoadTest.Serialization.LeftLobby do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3
end

defmodule ArenaLoadTest.Serialization.JoinedLobby do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3
end

defmodule ArenaLoadTest.Serialization.GameEvent do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  oneof(:event, 0)

  field(:joined, 1, type: ArenaLoadTest.Serialization.GameJoined, oneof: 0)
  field(:update, 2, type: ArenaLoadTest.Serialization.GameState, oneof: 0)
  field(:finished, 3, type: ArenaLoadTest.Serialization.GameFinished, oneof: 0)

  field(:toggle_bots, 4,
    type: ArenaLoadTest.Serialization.ToggleBots,
    json_name: "toggleBots",
    oneof: 0
  )

  field(:bounty_selected, 5,
    type: ArenaLoadTest.Serialization.BountySelected,
    json_name: "bountySelected",
    oneof: 0
  )
end

defmodule ArenaLoadTest.Serialization.BountySelected do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:bounty, 1, type: ArenaLoadTest.Serialization.BountyInfo)
end

defmodule ArenaLoadTest.Serialization.GameFinished.WinnersEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameFinished.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameFinished do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:winners, 1,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameFinished.WinnersEntry,
    map: true
  )

  field(:players, 2,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameFinished.PlayersEntry,
    map: true
  )
end

defmodule ArenaLoadTest.Serialization.GameJoined do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:config, 2, type: ArenaLoadTest.Serialization.Configuration)
  field(:bounties, 3, repeated: true, type: ArenaLoadTest.Serialization.BountyInfo)
  field(:team, 4, type: :uint32)
  field(:map, 5, type: :string)
end

defmodule ArenaLoadTest.Serialization.Configuration do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:game, 1, type: ArenaLoadTest.Serialization.ConfigGame)
  field(:map, 2, type: ArenaLoadTest.Serialization.ConfigMap)
  field(:characters, 3, repeated: true, type: ArenaLoadTest.Serialization.ConfigCharacter)

  field(:client_config, 4,
    type: ArenaLoadTest.Serialization.ClientConfig,
    json_name: "clientConfig"
  )
end

defmodule ArenaLoadTest.Serialization.ConfigGame do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:tick_rate_ms, 1, type: :float, json_name: "tickRateMs")
  field(:bounty_pick_time_ms, 2, type: :float, json_name: "bountyPickTimeMs")
  field(:start_game_time_ms, 3, type: :float, json_name: "startGameTimeMs")

  field(:game_mode, 4,
    type: ArenaLoadTest.Serialization.GameMode,
    json_name: "gameMode",
    enum: true
  )
end

defmodule ArenaLoadTest.Serialization.ConfigMap do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:radius, 1, type: :float)
  field(:name, 2, type: :string)
end

defmodule ArenaLoadTest.Serialization.ConfigCharacter.SkillsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: ArenaLoadTest.Serialization.ConfigSkill)
end

defmodule ArenaLoadTest.Serialization.ConfigCharacter do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

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

  field(:base_mana, 8, type: :uint64, json_name: "baseMana")
end

defmodule ArenaLoadTest.Serialization.ClientConfig do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:server_update, 1,
    type: ArenaLoadTest.Serialization.ConfigServerUpdate,
    json_name: "serverUpdate"
  )
end

defmodule ArenaLoadTest.Serialization.ConfigServerUpdate do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

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

defmodule ArenaLoadTest.Serialization.ConfigSkill do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:name, 1, type: :string)
  field(:cooldown_ms, 2, type: :uint64, json_name: "cooldownMs")
  field(:execution_duration_ms, 3, type: :uint64, json_name: "executionDurationMs")
  field(:targetting_radius, 4, type: :float, json_name: "targettingRadius")
  field(:targetting_angle, 5, type: :float, json_name: "targettingAngle")
  field(:targetting_range, 6, type: :float, json_name: "targettingRange")
  field(:stamina_cost, 7, type: :uint64, json_name: "staminaCost")
  field(:targetting_offset, 8, type: :float, json_name: "targettingOffset")
  field(:mana_cost, 9, type: :uint64, json_name: "manaCost")
  field(:is_combo, 10, type: :bool, json_name: "isCombo")

  field(:attack_type, 11,
    type: ArenaLoadTest.Serialization.AttackType,
    json_name: "attackType",
    enum: true
  )

  field(:skill_type, 12,
    type: ArenaLoadTest.Serialization.SkillType,
    json_name: "skillType",
    enum: true
  )
end

defmodule ArenaLoadTest.Serialization.GameState.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.ProjectilesEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.PlayerTimestampsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :int64)
end

defmodule ArenaLoadTest.Serialization.GameState.DamageTakenEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.GameState.DamageDoneEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.GameState.PowerUpsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.ItemsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.ObstaclesEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.PoolsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.CratesEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.BushesEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState.TrapsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: ArenaLoadTest.Serialization.Entity)
end

defmodule ArenaLoadTest.Serialization.GameState do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

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

  field(:obstacles, 14,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.ObstaclesEntry,
    map: true
  )

  field(:pools, 15,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.PoolsEntry,
    map: true
  )

  field(:crates, 16,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.CratesEntry,
    map: true
  )

  field(:bushes, 17,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.BushesEntry,
    map: true
  )

  field(:traps, 18,
    repeated: true,
    type: ArenaLoadTest.Serialization.GameState.TrapsEntry,
    map: true
  )

  field(:external_wall, 19, type: ArenaLoadTest.Serialization.Entity, json_name: "externalWall")
end

defmodule ArenaLoadTest.Serialization.Entity do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  oneof(:aditional_info, 0)

  field(:id, 1, proto3_optional: true, type: :uint64)
  field(:category, 2, proto3_optional: true, type: :string)
  field(:shape, 3, proto3_optional: true, type: :string)
  field(:name, 4, proto3_optional: true, type: :string)
  field(:position, 5, type: ArenaLoadTest.Serialization.Position)
  field(:radius, 6, proto3_optional: true, type: :float)
  field(:vertices, 7, proto3_optional: true, type: ArenaLoadTest.Serialization.ListPositionPB)
  field(:collides_with, 8, repeated: true, type: :uint64, json_name: "collidesWith")
  field(:speed, 9, proto3_optional: true, type: :float)
  field(:direction, 10, type: ArenaLoadTest.Serialization.Direction)
  field(:is_moving, 11, proto3_optional: true, type: :bool, json_name: "isMoving")
  field(:player, 12, type: ArenaLoadTest.Serialization.Player, oneof: 0)
  field(:projectile, 13, type: ArenaLoadTest.Serialization.Projectile, oneof: 0)
  field(:obstacle, 14, type: ArenaLoadTest.Serialization.Obstacle, oneof: 0)
  field(:power_up, 15, type: ArenaLoadTest.Serialization.PowerUp, json_name: "powerUp", oneof: 0)
  field(:item, 16, type: ArenaLoadTest.Serialization.Item, oneof: 0)
  field(:pool, 17, type: ArenaLoadTest.Serialization.Pool, oneof: 0)
  field(:crate, 18, type: ArenaLoadTest.Serialization.Crate, oneof: 0)
  field(:bush, 19, type: ArenaLoadTest.Serialization.Bush, oneof: 0)
  field(:trap, 20, type: ArenaLoadTest.Serialization.Trap, oneof: 0)
end

defmodule ArenaLoadTest.Serialization.Player.CooldownsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :string)
  field(:value, 2, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.Player.InventoryEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint32)
  field(:value, 2, type: ArenaLoadTest.Serialization.Item)
end

defmodule ArenaLoadTest.Serialization.Player do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:health, 1, proto3_optional: true, type: :uint64)
  field(:kill_count, 2, proto3_optional: true, type: :uint64, json_name: "killCount")

  field(:current_actions, 3,
    repeated: true,
    type: ArenaLoadTest.Serialization.PlayerAction,
    json_name: "currentActions"
  )

  field(:available_stamina, 4, proto3_optional: true, type: :uint64, json_name: "availableStamina")
  field(:max_stamina, 5, proto3_optional: true, type: :uint64, json_name: "maxStamina")
  field(:stamina_interval, 6, proto3_optional: true, type: :uint64, json_name: "staminaInterval")
  field(:recharging_stamina, 7, proto3_optional: true, type: :bool, json_name: "rechargingStamina")
  field(:character_name, 8, proto3_optional: true, type: :string, json_name: "characterName")
  field(:power_ups, 9, proto3_optional: true, type: :uint64, json_name: "powerUps")
  field(:effects, 10, repeated: true, type: ArenaLoadTest.Serialization.Effect)

  field(:cooldowns, 11,
    repeated: true,
    type: ArenaLoadTest.Serialization.Player.CooldownsEntry,
    map: true
  )

  field(:visible_players, 12, repeated: true, type: :uint64, json_name: "visiblePlayers")
  field(:on_bush, 13, proto3_optional: true, type: :bool, json_name: "onBush")
  field(:forced_movement, 14, proto3_optional: true, type: :bool, json_name: "forcedMovement")
  field(:bounty_completed, 15, proto3_optional: true, type: :bool, json_name: "bountyCompleted")
  field(:mana, 16, proto3_optional: true, type: :uint64)

  field(:current_basic_animation, 17,
    proto3_optional: true,
    type: :uint32,
    json_name: "currentBasicAnimation"
  )

  field(:match_position, 18, proto3_optional: true, type: :uint32, json_name: "matchPosition")
  field(:team, 19, proto3_optional: true, type: :uint32)
  field(:max_health, 20, proto3_optional: true, type: :uint64, json_name: "maxHealth")

  field(:inventory, 21,
    repeated: true,
    type: ArenaLoadTest.Serialization.Player.InventoryEntry,
    map: true
  )

  field(:blocked_actions, 22, proto3_optional: true, type: :bool, json_name: "blockedActions")
  field(:skin_name, 23, proto3_optional: true, type: :string, json_name: "skinName")
  field(:character_level, 24, proto3_optional: true, type: :uint64, json_name: "characterLevel")
end

defmodule ArenaLoadTest.Serialization.Effect do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:name, 1, type: :string)
  field(:duration_ms, 2, type: :uint32, json_name: "durationMs")
  field(:id, 3, type: :uint64)
end

defmodule ArenaLoadTest.Serialization.Item.PickUpTimeElapsedEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:key, 1, type: :uint32)
  field(:value, 2, type: :uint32)
end

defmodule ArenaLoadTest.Serialization.Item do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:name, 2, proto3_optional: true, type: :string)

  field(:pick_up_time_elapsed, 3,
    repeated: true,
    type: ArenaLoadTest.Serialization.Item.PickUpTimeElapsedEntry,
    json_name: "pickUpTimeElapsed",
    map: true
  )

  field(:mechanic_radius, 4, proto3_optional: true, type: :float, json_name: "mechanicRadius")
  field(:status, 5, type: ArenaLoadTest.Serialization.ItemStatus, enum: true)
  field(:owner_id, 6, proto3_optional: true, type: :uint64, json_name: "ownerId")
end

defmodule ArenaLoadTest.Serialization.Projectile do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:damage, 1, proto3_optional: true, type: :uint64)
  field(:owner_id, 2, proto3_optional: true, type: :uint64, json_name: "ownerId")
  field(:status, 3, type: ArenaLoadTest.Serialization.ProjectileStatus, enum: true)
  field(:skill_key, 4, proto3_optional: true, type: :string, json_name: "skillKey")
end

defmodule ArenaLoadTest.Serialization.Obstacle do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:color, 1, proto3_optional: true, type: :string)
  field(:collisionable, 2, proto3_optional: true, type: :bool)
  field(:status, 3, proto3_optional: true, type: :string)
  field(:type, 4, proto3_optional: true, type: :string)
end

defmodule ArenaLoadTest.Serialization.PowerUp do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:status, 2, type: ArenaLoadTest.Serialization.PowerUpstatus, enum: true)
end

defmodule ArenaLoadTest.Serialization.Crate do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:health, 1, proto3_optional: true, type: :uint64)

  field(:amount_of_power_ups, 2,
    proto3_optional: true,
    type: :uint64,
    json_name: "amountOfPowerUps"
  )

  field(:status, 3, type: ArenaLoadTest.Serialization.CrateStatus, enum: true)
end

defmodule ArenaLoadTest.Serialization.Pool do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:status, 2, type: ArenaLoadTest.Serialization.PoolStatus, enum: true)
  field(:effects, 3, repeated: true, type: ArenaLoadTest.Serialization.Effect)
  field(:skill_key, 4, type: :string, json_name: "skillKey")
end

defmodule ArenaLoadTest.Serialization.Bush do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3
end

defmodule ArenaLoadTest.Serialization.Trap do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:name, 2, type: :string)
  field(:status, 3, type: ArenaLoadTest.Serialization.TrapStatus, enum: true)
end

defmodule ArenaLoadTest.Serialization.PlayerAction do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:action, 1, type: ArenaLoadTest.Serialization.PlayerActionType, enum: true)
  field(:duration, 2, type: :uint64)
  field(:destination, 3, type: ArenaLoadTest.Serialization.Position)
  field(:direction, 4, type: ArenaLoadTest.Serialization.Position)
end

defmodule ArenaLoadTest.Serialization.Move do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:direction, 1, type: ArenaLoadTest.Serialization.Direction)
end

defmodule ArenaLoadTest.Serialization.Attack do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:skill, 1, type: :string)
  field(:parameters, 2, type: ArenaLoadTest.Serialization.AttackParameters)
end

defmodule ArenaLoadTest.Serialization.AttackParameters do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:target, 1, type: ArenaLoadTest.Serialization.Direction)
end

defmodule ArenaLoadTest.Serialization.UseItem do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:item_position, 1, type: :uint64, json_name: "itemPosition")
end

defmodule ArenaLoadTest.Serialization.SelectBounty do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:bounty_quest_id, 1, type: :string, json_name: "bountyQuestId")
end

defmodule ArenaLoadTest.Serialization.ToggleZone do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3
end

defmodule ArenaLoadTest.Serialization.ToggleBots do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3
end

defmodule ArenaLoadTest.Serialization.ChangeTickrate do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:tickrate, 1, type: :int64)
end

defmodule ArenaLoadTest.Serialization.GameAction do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  oneof(:action_type, 0)

  field(:move, 1, type: ArenaLoadTest.Serialization.Move, oneof: 0)
  field(:attack, 2, type: ArenaLoadTest.Serialization.Attack, oneof: 0)
  field(:use_item, 4, type: ArenaLoadTest.Serialization.UseItem, json_name: "useItem", oneof: 0)

  field(:select_bounty, 5,
    type: ArenaLoadTest.Serialization.SelectBounty,
    json_name: "selectBounty",
    oneof: 0
  )

  field(:toggle_zone, 6,
    type: ArenaLoadTest.Serialization.ToggleZone,
    json_name: "toggleZone",
    oneof: 0
  )

  field(:toggle_bots, 7,
    type: ArenaLoadTest.Serialization.ToggleBots,
    json_name: "toggleBots",
    oneof: 0
  )

  field(:change_tickrate, 8,
    type: ArenaLoadTest.Serialization.ChangeTickrate,
    json_name: "changeTickrate",
    oneof: 0
  )

  field(:timestamp, 3, type: :int64)
end

defmodule ArenaLoadTest.Serialization.Zone do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:radius, 1, type: :float)
  field(:enabled, 2, type: :bool)
  field(:next_zone_change_timestamp, 3, type: :int64, json_name: "nextZoneChangeTimestamp")
  field(:shrinking, 4, type: :bool)
end

defmodule ArenaLoadTest.Serialization.KillEntry do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:killer_id, 1, type: :uint64, json_name: "killerId")
  field(:victim_id, 2, type: :uint64, json_name: "victimId")
end

defmodule ArenaLoadTest.Serialization.BountyInfo do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:id, 1, type: :string)
  field(:description, 2, type: :string)
  field(:quest_type, 3, type: :string, json_name: "questType")
  field(:reward, 4, type: ArenaLoadTest.Serialization.CurrencyReward)
end

defmodule ArenaLoadTest.Serialization.CurrencyReward do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto3

  field(:currency, 1, type: :string)
  field(:amount, 2, type: :int64)
end

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

defmodule GameClient.Protobuf.CrateStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:FINE, 0)
  field(:DESTROYED, 1)
end

defmodule GameClient.Protobuf.PowerUpstatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:AVAILABLE, 0)
  field(:TAKEN, 1)
end

defmodule GameClient.Protobuf.PlayerActionType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:MOVING, 0)
  field(:STARTING_SKILL_1, 1)
  field(:STARTING_SKILL_2, 2)
  field(:EXECUTING_SKILL_1, 3)
  field(:EXECUTING_SKILL_2, 4)
  field(:EXECUTING_SKILL_3, 5)
end

defmodule GameClient.Protobuf.TrapStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PENDING, 0)
  field(:PREPARED, 1)
  field(:TRIGGERED, 2)
  field(:USED, 3)
end

defmodule GameClient.Protobuf.Direction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule GameClient.Protobuf.Position do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule GameClient.Protobuf.LobbyEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:leave, 1, type: GameClient.Protobuf.LeaveLobby, oneof: 0)
  field(:left, 2, type: GameClient.Protobuf.LeftLobby, oneof: 0)
  field(:joined, 3, type: GameClient.Protobuf.JoinedLobby, oneof: 0)
  field(:game, 4, type: GameClient.Protobuf.GameState, oneof: 0)
end

defmodule GameClient.Protobuf.LeaveLobby do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.LeftLobby do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.JoinedLobby do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.GameEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:joined, 1, type: GameClient.Protobuf.GameJoined, oneof: 0)
  field(:update, 2, type: GameClient.Protobuf.GameState, oneof: 0)
  field(:finished, 3, type: GameClient.Protobuf.GameFinished, oneof: 0)
  field(:ping, 4, type: GameClient.Protobuf.PingUpdate, oneof: 0)
  field(:toggle_bots, 5, type: GameClient.Protobuf.ToggleBots, json_name: "toggleBots", oneof: 0)
end

defmodule GameClient.Protobuf.GameFinished.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameFinished do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:winner, 1, type: GameClient.Protobuf.Entity)

  field(:players, 2,
    repeated: true,
    type: GameClient.Protobuf.GameFinished.PlayersEntry,
    map: true
  )
end

defmodule GameClient.Protobuf.PingUpdate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:latency, 1, type: :uint64)
end

defmodule GameClient.Protobuf.GameJoined do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:config, 2, type: GameClient.Protobuf.Configuration)
  field(:bounties, 3, repeated: true, type: GameClient.Protobuf.BountyInfo)
end

defmodule GameClient.Protobuf.Configuration do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game, 1, type: GameClient.Protobuf.ConfigGame)
  field(:map, 2, type: GameClient.Protobuf.ConfigMap)
  field(:characters, 3, repeated: true, type: GameClient.Protobuf.ConfigCharacter)
  field(:client_config, 4, type: GameClient.Protobuf.ClientConfig, json_name: "clientConfig")
end

defmodule GameClient.Protobuf.ConfigGame do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:tick_rate_ms, 1, type: :float, json_name: "tickRateMs")
  field(:bounty_pick_time_ms, 2, type: :float, json_name: "bountyPickTimeMs")
  field(:start_game_time_ms, 3, type: :float, json_name: "startGameTimeMs")
end

defmodule GameClient.Protobuf.ConfigMap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
end

defmodule GameClient.Protobuf.ConfigCharacter.SkillsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: GameClient.Protobuf.ConfigSkill)
end

defmodule GameClient.Protobuf.ConfigCharacter do
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
    type: GameClient.Protobuf.ConfigCharacter.SkillsEntry,
    map: true
  )
end

defmodule GameClient.Protobuf.ClientConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:server_update, 1, type: GameClient.Protobuf.ConfigServerUpdate, json_name: "serverUpdate")
end

defmodule GameClient.Protobuf.ConfigServerUpdate do
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

defmodule GameClient.Protobuf.ConfigSkill do
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

defmodule GameClient.Protobuf.GameState.PlayersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState.ProjectilesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState.PlayerTimestampsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :int64)
end

defmodule GameClient.Protobuf.GameState.DamageTakenEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule GameClient.Protobuf.GameState.DamageDoneEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :uint64)
end

defmodule GameClient.Protobuf.GameState.PowerUpsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState.ItemsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState.ObstaclesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState.PoolsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState.CratesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState.BushesEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState.TrapsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: GameClient.Protobuf.Entity)
end

defmodule GameClient.Protobuf.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:game_id, 1, type: :string, json_name: "gameId")
  field(:players, 2, repeated: true, type: GameClient.Protobuf.GameState.PlayersEntry, map: true)

  field(:projectiles, 3,
    repeated: true,
    type: GameClient.Protobuf.GameState.ProjectilesEntry,
    map: true
  )

  field(:player_timestamps, 4,
    repeated: true,
    type: GameClient.Protobuf.GameState.PlayerTimestampsEntry,
    json_name: "playerTimestamps",
    map: true
  )

  field(:server_timestamp, 5, type: :int64, json_name: "serverTimestamp")
  field(:zone, 6, type: GameClient.Protobuf.Zone)
  field(:killfeed, 7, repeated: true, type: GameClient.Protobuf.KillEntry)

  field(:damage_taken, 8,
    repeated: true,
    type: GameClient.Protobuf.GameState.DamageTakenEntry,
    json_name: "damageTaken",
    map: true
  )

  field(:damage_done, 9,
    repeated: true,
    type: GameClient.Protobuf.GameState.DamageDoneEntry,
    json_name: "damageDone",
    map: true
  )

  field(:power_ups, 10,
    repeated: true,
    type: GameClient.Protobuf.GameState.PowerUpsEntry,
    json_name: "powerUps",
    map: true
  )

  field(:status, 11, type: GameClient.Protobuf.GameStatus, enum: true)
  field(:start_game_timestamp, 12, type: :int64, json_name: "startGameTimestamp")
  field(:items, 13, repeated: true, type: GameClient.Protobuf.GameState.ItemsEntry, map: true)

  field(:obstacles, 14,
    repeated: true,
    type: GameClient.Protobuf.GameState.ObstaclesEntry,
    map: true
  )

  field(:pools, 15, repeated: true, type: GameClient.Protobuf.GameState.PoolsEntry, map: true)
  field(:crates, 16, repeated: true, type: GameClient.Protobuf.GameState.CratesEntry, map: true)
  field(:bushes, 17, repeated: true, type: GameClient.Protobuf.GameState.BushesEntry, map: true)
  field(:traps, 18, repeated: true, type: GameClient.Protobuf.GameState.TrapsEntry, map: true)
end

defmodule GameClient.Protobuf.Entity do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:aditional_info, 0)

  field(:id, 1, type: :uint64)
  field(:category, 2, type: :string)
  field(:shape, 3, type: :string)
  field(:name, 4, type: :string)
  field(:position, 5, type: GameClient.Protobuf.Position)
  field(:radius, 6, type: :float)
  field(:vertices, 7, repeated: true, type: GameClient.Protobuf.Position)
  field(:collides_with, 8, repeated: true, type: :uint64, json_name: "collidesWith")
  field(:speed, 9, type: :float)
  field(:direction, 10, type: GameClient.Protobuf.Direction)
  field(:is_moving, 11, type: :bool, json_name: "isMoving")
  field(:player, 12, type: GameClient.Protobuf.Player, oneof: 0)
  field(:projectile, 13, type: GameClient.Protobuf.Projectile, oneof: 0)
  field(:obstacle, 14, type: GameClient.Protobuf.Obstacle, oneof: 0)
  field(:power_up, 15, type: GameClient.Protobuf.PowerUp, json_name: "powerUp", oneof: 0)
  field(:item, 16, type: GameClient.Protobuf.Item, oneof: 0)
  field(:pool, 17, type: GameClient.Protobuf.Pool, oneof: 0)
  field(:crate, 18, type: GameClient.Protobuf.Crate, oneof: 0)
  field(:bush, 19, type: GameClient.Protobuf.Bush, oneof: 0)
  field(:trap, 20, type: GameClient.Protobuf.Trap, oneof: 0)
end

defmodule GameClient.Protobuf.Player.CooldownsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: :uint64)
end

defmodule GameClient.Protobuf.Player do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:health, 1, type: :uint64)
  field(:kill_count, 2, type: :uint64, json_name: "killCount")

  field(:current_actions, 3,
    repeated: true,
    type: GameClient.Protobuf.PlayerAction,
    json_name: "currentActions"
  )

  field(:available_stamina, 4, type: :uint64, json_name: "availableStamina")
  field(:max_stamina, 5, type: :uint64, json_name: "maxStamina")
  field(:stamina_interval, 6, type: :uint64, json_name: "staminaInterval")
  field(:recharging_stamina, 7, type: :bool, json_name: "rechargingStamina")
  field(:character_name, 8, type: :string, json_name: "characterName")
  field(:power_ups, 9, type: :uint64, json_name: "powerUps")
  field(:effects, 10, repeated: true, type: GameClient.Protobuf.Effect)
  field(:inventory, 11, type: GameClient.Protobuf.Item)
  field(:cooldowns, 12, repeated: true, type: GameClient.Protobuf.Player.CooldownsEntry, map: true)
  field(:visible_players, 13, repeated: true, type: :uint64, json_name: "visiblePlayers")
  field(:on_bush, 14, type: :bool, json_name: "onBush")
  field(:forced_movement, 15, type: :bool, json_name: "forcedMovement")
  field(:default_bounty, 16, type: GameClient.Protobuf.BountyInfo, json_name: "defaultBounty")
  field(:bounty_completed, 17, type: :bool, json_name: "bountyCompleted")
end

defmodule GameClient.Protobuf.Effect do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:duration_ms, 2, type: :uint32, json_name: "durationMs")
end

defmodule GameClient.Protobuf.Item do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 2, type: :string)
end

defmodule GameClient.Protobuf.Projectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:damage, 1, type: :uint64)
  field(:owner_id, 2, type: :uint64, json_name: "ownerId")
  field(:status, 3, type: GameClient.Protobuf.ProjectileStatus, enum: true)
  field(:skill_key, 4, type: :string, json_name: "skillKey")
end

defmodule GameClient.Protobuf.Obstacle do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:color, 1, type: :string)
end

defmodule GameClient.Protobuf.PowerUp do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:status, 2, type: GameClient.Protobuf.PowerUpstatus, enum: true)
end

defmodule GameClient.Protobuf.Crate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:health, 1, type: :uint64)
  field(:amount_of_power_ups, 2, type: :uint64, json_name: "amountOfPowerUps")
  field(:status, 3, type: GameClient.Protobuf.CrateStatus, enum: true)
end

defmodule GameClient.Protobuf.Pool do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
end

defmodule GameClient.Protobuf.Bush do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.Trap do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:owner_id, 1, type: :uint64, json_name: "ownerId")
  field(:name, 2, type: :string)
  field(:status, 3, type: GameClient.Protobuf.TrapStatus, enum: true)
end

defmodule GameClient.Protobuf.PlayerAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:action, 1, type: GameClient.Protobuf.PlayerActionType, enum: true)
  field(:duration, 2, type: :uint64)
  field(:destination, 3, type: GameClient.Protobuf.Position)
  field(:direction, 4, type: GameClient.Protobuf.Position)
end

defmodule GameClient.Protobuf.Move do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:direction, 1, type: GameClient.Protobuf.Direction)
end

defmodule GameClient.Protobuf.Attack do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:skill, 1, type: :string)
  field(:parameters, 2, type: GameClient.Protobuf.AttackParameters)
end

defmodule GameClient.Protobuf.AttackParameters do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:target, 1, type: GameClient.Protobuf.Direction)
end

defmodule GameClient.Protobuf.UseItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:item, 1, type: :uint64)
end

defmodule GameClient.Protobuf.SelectBounty do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:bounty_quest_id, 1, type: :string, json_name: "bountyQuestId")
end

defmodule GameClient.Protobuf.ToggleZone do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.ToggleBots do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"
end

defmodule GameClient.Protobuf.ChangeTickrate do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:tickrate, 1, type: :int64)
end

defmodule GameClient.Protobuf.GameAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field(:move, 1, type: GameClient.Protobuf.Move, oneof: 0)
  field(:attack, 2, type: GameClient.Protobuf.Attack, oneof: 0)
  field(:use_item, 4, type: GameClient.Protobuf.UseItem, json_name: "useItem", oneof: 0)

  field(:select_bounty, 5,
    type: GameClient.Protobuf.SelectBounty,
    json_name: "selectBounty",
    oneof: 0
  )

  field(:toggle_zone, 6, type: GameClient.Protobuf.ToggleZone, json_name: "toggleZone", oneof: 0)
  field(:toggle_bots, 7, type: GameClient.Protobuf.ToggleBots, json_name: "toggleBots", oneof: 0)

  field(:change_tickrate, 8,
    type: GameClient.Protobuf.ChangeTickrate,
    json_name: "changeTickrate",
    oneof: 0
  )

  field(:timestamp, 3, type: :int64)
end

defmodule GameClient.Protobuf.Zone do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:radius, 1, type: :float)
  field(:enabled, 2, type: :bool)
  field(:next_zone_change_timestamp, 3, type: :int64, json_name: "nextZoneChangeTimestamp")
  field(:shrinking, 4, type: :bool)
end

defmodule GameClient.Protobuf.KillEntry do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:killer_id, 1, type: :uint64, json_name: "killerId")
  field(:victim_id, 2, type: :uint64, json_name: "victimId")
end

defmodule GameClient.Protobuf.BountyInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :string)
  field(:description, 2, type: :string)
  field(:quest_type, 3, type: :string, json_name: "questType")
  field(:reward, 4, type: GameClient.Protobuf.CurrencyReward)
end

defmodule GameClient.Protobuf.CurrencyReward do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:currency, 1, type: :string)
  field(:amount, 2, type: :int64)
end

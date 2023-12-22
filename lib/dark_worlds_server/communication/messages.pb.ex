defmodule DarkWorldsServer.Communication.Proto.PlayerStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PLAYER_STATUS_UNDEFINED, 0)
  field(:PLAYER_STATUS_ALIVE, 1)
  field(:PLAYER_STATUS_DEAD, 2)
end

defmodule DarkWorldsServer.Communication.Proto.PlayerActionEnum do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PLAYER_ACTION_ENUM_UNDEFINED, 0)
  field(:PLAYER_ACTION_ENUM_NOTHING, 1)
  field(:PLAYER_ACTION_ENUM_MOVING, 2)
  field(:PLAYER_ACTION_ENUM_USING_SKILL, 3)
end

defmodule DarkWorldsServer.Communication.Proto.KillEntity do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:KILL_ENTITY_UNDEFINED, 0)
  field(:KILL_ENTITY_PLAYER, 1)
  field(:KILL_ENTITY_ITEM, 2)
  field(:KILL_ENTITY_ZONE, 3)
end

defmodule DarkWorldsServer.Communication.Proto.GameEventType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:STATE_UPDATE, 0)
  field(:PING_UPDATE, 1)
  field(:PLAYER_JOINED, 2)
  field(:GAME_FINISHED, 3)
  field(:GAME_STARTED, 4)
end

defmodule DarkWorldsServer.Communication.Proto.OldStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:ALIVE, 0)
  field(:DEAD, 1)
end

defmodule DarkWorldsServer.Communication.Proto.Action do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:ACTION_UNSPECIFIED, 0)
  field(:ATTACK, 1)
  field(:TELEPORT, 2)
  field(:ATTACK_AOE, 3)
  field(:MOVE_WITH_JOYSTICK, 4)
  field(:ADD_BOT, 5)
  field(:AUTO_ATTACK, 6)
  field(:BASIC_ATTACK, 7)
  field(:SKILL_1, 8)
  field(:SKILL_2, 9)
  field(:SKILL_3, 10)
  field(:SKILL_4, 11)
  field(:SELECT_CHARACTER, 12)
  field(:ENABLE_BOTS, 13)
  field(:DISABLE_BOTS, 14)
end

defmodule DarkWorldsServer.Communication.Proto.Direction do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:DIRECTION_UNSPECIFIED, 0)
  field(:UP, 1)
  field(:DOWN, 2)
  field(:LEFT, 3)
  field(:RIGHT, 4)
end

defmodule DarkWorldsServer.Communication.Proto.OldPlayerAction do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:NOTHING, 0)
  field(:ATTACKING, 1)
  field(:ATTACKING_AOE, 2)
  field(:STARTING_SKILL_1, 3)
  field(:STARTING_SKILL_2, 4)
  field(:STARTING_SKILL_3, 5)
  field(:STARTING_SKILL_4, 6)
  field(:EXECUTING_SKILL_1, 7)
  field(:EXECUTING_SKILL_2, 8)
  field(:EXECUTING_SKILL_3, 9)
  field(:EXECUTING_SKILL_4, 10)
  field(:MOVING, 11)
end

defmodule DarkWorldsServer.Communication.Proto.PlayerEffect do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:PETRIFIED, 0)
  field(:DISARMED, 1)
  field(:DENIAL_OF_SERVICE, 2)
  field(:RAGED, 3)
  field(:NEON_CRASHING, 4)
  field(:LEAPING, 5)
  field(:OUT_OF_AREA, 6)
  field(:ELNAR_MARK, 7)
  field(:YUGEN_MARK, 8)
  field(:XANDA_MARK, 9)
  field(:XANDA_MARK_OWNER, 10)
  field(:POISONED, 11)
  field(:SLOWED, 12)
  field(:FIERY_RAMPAGE, 13)
  field(:BURNED, 14)
  field(:SCHERZO, 15)
  field(:DANSE_MACABRE, 16)
  field(:PARALYZED, 17)
  field(:NONE, 18)
end

defmodule DarkWorldsServer.Communication.Proto.LobbyEventType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:TYPE_UNSPECIFIED, 0)
  field(:CONNECTED, 1)
  field(:PLAYER_ADDED, 2)
  field(:PREPARING_GAME, 3)
  field(:START_GAME, 4)
  field(:NOTIFY_PLAYER_AMOUNT, 5)
end

defmodule DarkWorldsServer.Communication.Proto.ProjectileType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:BULLET, 0)
  field(:DISARMING_BULLET, 1)
end

defmodule DarkWorldsServer.Communication.Proto.ProjectileStatus do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:ACTIVE, 0)
  field(:EXPLODED, 1)
end

defmodule DarkWorldsServer.Communication.Proto.LootType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:LOOT_TYPE_UNSPECIFIED, 0)
  field(:LOOT_HEALTH, 1)
end

defmodule DarkWorldsServer.Communication.Proto.ModifierType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:MULTIPLICATIVE, 0)
  field(:ADDITIVE, 1)
end

defmodule DarkWorldsServer.Communication.Proto.MechanicType do
  @moduledoc false

  use Protobuf, enum: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:HIT, 0)
  field(:SIMPLE_SHOOT, 1)
  field(:MULTI_SHOOT, 2)
  field(:GIVE_EFFECT, 3)
end

defmodule DarkWorldsServer.Communication.Proto.TransitionGameEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:new_game_event, 1,
    type: DarkWorldsServer.Communication.Proto.GameEvent,
    json_name: "newGameEvent"
  )

  field(:old_game_event, 2,
    type: DarkWorldsServer.Communication.Proto.OldGameEvent,
    json_name: "oldGameEvent"
  )

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:event, 0)

  field(:game_state, 1,
    type: DarkWorldsServer.Communication.Proto.GameState,
    json_name: "gameState",
    oneof: 0
  )

  field(:game_started, 2,
    type: DarkWorldsServer.Communication.Proto.GameStarted,
    json_name: "gameStarted",
    oneof: 0
  )

  field(:game_finished, 3,
    type: DarkWorldsServer.Communication.Proto.GameFinished,
    json_name: "gameFinished",
    oneof: 0
  )

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameStarted do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:starting_state, 1,
    type: DarkWorldsServer.Communication.Proto.GameState,
    json_name: "startingState"
  )

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameFinished do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:winner, 1, type: DarkWorldsServer.Communication.Proto.Player)
  field(:players, 2, repeated: true, type: DarkWorldsServer.Communication.Proto.Player)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameState do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:players, 1, repeated: true, type: DarkWorldsServer.Communication.Proto.Player)
  field(:projectiles, 2, repeated: true, type: DarkWorldsServer.Communication.Proto.Projectile)
  field(:items, 3, repeated: true, type: DarkWorldsServer.Communication.Proto.Item)
  field(:zone_info, 4, type: DarkWorldsServer.Communication.Proto.ZoneInfo, json_name: "zoneInfo")
  field(:killfeed, 5, repeated: true, type: DarkWorldsServer.Communication.Proto.KillEvent)
  field(:player_timestamp, 6, type: :int64, json_name: "playerTimestamp")
  field(:server_timestamp, 7, type: :int64, json_name: "serverTimestamp")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.Player do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :uint64)
  field(:position, 2, type: DarkWorldsServer.Communication.Proto.Position)
  field(:health, 3, type: :sint64)
  field(:speed, 4, type: :float)
  field(:size, 5, type: :float)
  field(:direction, 6, type: :float)
  field(:status, 7, type: DarkWorldsServer.Communication.Proto.PlayerStatus, enum: true)
  field(:kill_count, 8, type: :uint64, json_name: "killCount")
  field(:death_count, 9, type: :uint64, json_name: "deathCount")
  field(:action, 10, repeated: true, type: DarkWorldsServer.Communication.Proto.ActionTracker)
  field(:action_duration_ms, 11, type: :uint64, json_name: "actionDurationMs")
  field(:cooldowns, 12, repeated: true, type: DarkWorldsServer.Communication.Proto.SkillCooldown)
  field(:inventory, 13, repeated: true, type: DarkWorldsServer.Communication.Proto.Item)
  field(:effects, 14, repeated: true, type: DarkWorldsServer.Communication.Proto.EffectInfo)
  field(:character_name, 15, type: :string, json_name: "characterName")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.ActionTracker do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_action, 1,
    type: DarkWorldsServer.Communication.Proto.PlayerAction,
    json_name: "playerAction"
  )

  field(:duration, 2, type: :uint64)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.PlayerAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:action, 1, type: DarkWorldsServer.Communication.Proto.PlayerActionEnum, enum: true)
  field(:action_skill_key, 2, type: :string, json_name: "actionSkillKey")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.SkillCooldown do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:skill_key, 1, type: :string, json_name: "skillKey")
  field(:cooldown_ms, 2, type: :uint64, json_name: "cooldownMs")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.EffectInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:remaining_ms, 2, type: :uint64, json_name: "remainingMs")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.Item do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :uint64)
  field(:name, 2, type: :string)
  field(:size, 3, type: :float)
  field(:position, 4, type: DarkWorldsServer.Communication.Proto.Position)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.Projectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :uint64)
  field(:name, 2, type: :string)
  field(:damage, 3, type: :uint32)
  field(:speed, 4, type: :float)
  field(:size, 5, type: :float)
  field(:position, 6, type: DarkWorldsServer.Communication.Proto.Position)
  field(:direction, 7, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.ZoneInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:center, 1, type: DarkWorldsServer.Communication.Proto.Position)
  field(:radius, 2, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.Position do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.KillEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:killed_by_entity, 1,
    type: DarkWorldsServer.Communication.Proto.KillEntity,
    json_name: "killedByEntity",
    enum: true
  )

  field(:killed_by_id, 2, type: :uint64, json_name: "killedById")
  field(:killed, 3, type: :uint64)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldGameEvent.SelectedCharactersEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :string)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldGameEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:type, 1, type: DarkWorldsServer.Communication.Proto.GameEventType, enum: true)
  field(:players, 2, repeated: true, type: DarkWorldsServer.Communication.Proto.OldPlayer)
  field(:latency, 3, type: :uint64)
  field(:projectiles, 4, repeated: true, type: DarkWorldsServer.Communication.Proto.OldProjectile)
  field(:player_joined_id, 5, type: :uint64, json_name: "playerJoinedId")
  field(:player_joined_name, 6, type: :string, json_name: "playerJoinedName")

  field(:winner_player, 7,
    type: DarkWorldsServer.Communication.Proto.OldPlayer,
    json_name: "winnerPlayer"
  )

  field(:selected_characters, 8,
    repeated: true,
    type: DarkWorldsServer.Communication.Proto.OldGameEvent.SelectedCharactersEntry,
    json_name: "selectedCharacters",
    map: true
  )

  field(:player_timestamp, 9, type: :int64, json_name: "playerTimestamp")
  field(:server_timestamp, 10, type: :int64, json_name: "serverTimestamp")
  field(:killfeed, 11, repeated: true, type: DarkWorldsServer.Communication.Proto.OldKillEvent)
  field(:playable_radius, 12, type: :float, json_name: "playableRadius")

  field(:shrinking_center, 13,
    type: DarkWorldsServer.Communication.Proto.OldPosition,
    json_name: "shrinkingCenter"
  )

  field(:loots, 14, repeated: true, type: DarkWorldsServer.Communication.Proto.LootPackage)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.PlayerCharacter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:character_name, 2, type: :string, json_name: "characterName")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldPlayer.EffectsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :uint64)
  field(:value, 2, type: DarkWorldsServer.Communication.Proto.OldEffectInfo)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldPlayer do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :uint64)
  field(:health, 2, type: :sint64)
  field(:position, 3, type: DarkWorldsServer.Communication.Proto.OldPosition)
  field(:status, 4, type: DarkWorldsServer.Communication.Proto.OldStatus, enum: true)
  field(:action, 5, repeated: true, type: DarkWorldsServer.Communication.Proto.OldActionTracker)

  field(:aoe_position, 6,
    type: DarkWorldsServer.Communication.Proto.OldPosition,
    json_name: "aoePosition"
  )

  field(:kill_count, 7, type: :uint64, json_name: "killCount")
  field(:death_count, 8, type: :uint64, json_name: "deathCount")

  field(:basic_skill_cooldown_left, 9,
    type: DarkWorldsServer.Communication.Proto.MillisTime,
    json_name: "basicSkillCooldownLeft"
  )

  field(:skill_1_cooldown_left, 10,
    type: DarkWorldsServer.Communication.Proto.MillisTime,
    json_name: "skill1CooldownLeft"
  )

  field(:skill_2_cooldown_left, 11,
    type: DarkWorldsServer.Communication.Proto.MillisTime,
    json_name: "skill2CooldownLeft"
  )

  field(:skill_3_cooldown_left, 12,
    type: DarkWorldsServer.Communication.Proto.MillisTime,
    json_name: "skill3CooldownLeft"
  )

  field(:skill_4_cooldown_left, 13,
    type: DarkWorldsServer.Communication.Proto.MillisTime,
    json_name: "skill4CooldownLeft"
  )

  field(:character_name, 14, type: :string, json_name: "characterName")

  field(:effects, 15,
    repeated: true,
    type: DarkWorldsServer.Communication.Proto.OldPlayer.EffectsEntry,
    map: true
  )

  field(:direction, 16, type: DarkWorldsServer.Communication.Proto.RelativePosition)
  field(:body_size, 17, type: :float, json_name: "bodySize")
  field(:inventory, 18, repeated: true, type: DarkWorldsServer.Communication.Proto.GameLoot)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldActionTracker do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_action, 1,
    type: DarkWorldsServer.Communication.Proto.OldPlayerAction,
    json_name: "playerAction",
    enum: true
  )

  field(:duration, 2, type: :uint64)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldEffectInfo do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:ends_at, 1, type: DarkWorldsServer.Communication.Proto.MillisTime, json_name: "endsAt")
  field(:caused_by, 2, type: :uint64, json_name: "causedBy")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldKillEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:killed_by, 1, type: :uint64, json_name: "killedBy")
  field(:killed, 2, type: :uint64)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldPosition do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.RelativePosition do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.ClientAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:action, 1, type: DarkWorldsServer.Communication.Proto.Action, enum: true)
  field(:direction, 2, type: DarkWorldsServer.Communication.Proto.Direction, enum: true)
  field(:position, 3, type: DarkWorldsServer.Communication.Proto.RelativePosition)

  field(:move_delta, 4,
    type: DarkWorldsServer.Communication.Proto.RelativePosition,
    json_name: "moveDelta"
  )

  field(:target, 5, type: :sint64)
  field(:timestamp, 6, type: :int64)

  field(:player_character, 7,
    type: DarkWorldsServer.Communication.Proto.PlayerCharacter,
    json_name: "playerCharacter"
  )

  field(:angle, 8, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.LobbyEvent do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:type, 1, type: DarkWorldsServer.Communication.Proto.LobbyEventType, enum: true)
  field(:lobby_id, 2, type: :string, json_name: "lobbyId")

  field(:player_info, 3,
    type: DarkWorldsServer.Communication.Proto.PlayerInformation,
    json_name: "playerInfo"
  )

  field(:added_player_info, 4,
    type: DarkWorldsServer.Communication.Proto.PlayerInformation,
    json_name: "addedPlayerInfo"
  )

  field(:game_id, 5, type: :string, json_name: "gameId")
  field(:player_count, 6, type: :uint64, json_name: "playerCount")

  field(:players_info, 7,
    repeated: true,
    type: DarkWorldsServer.Communication.Proto.PlayerInformation,
    json_name: "playersInfo"
  )

  field(:removed_player_info, 8,
    type: DarkWorldsServer.Communication.Proto.PlayerInformation,
    json_name: "removedPlayerInfo"
  )

  field(:game_config, 9,
    type: DarkWorldsServer.Communication.Proto.Config,
    json_name: "gameConfig"
  )

  field(:server_hash, 10, type: :string, json_name: "serverHash")
  field(:host_player_id, 11, type: :uint64, json_name: "hostPlayerId")
  field(:amount_of_players, 12, type: :uint64, json_name: "amountOfPlayers")
  field(:capacity, 13, type: :uint64)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.PlayerInformation do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:player_name, 2, type: :string, json_name: "playerName")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.RunnerConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:Name, 1, type: :string)
  field(:board_width, 2, type: :uint64, json_name: "boardWidth")
  field(:board_height, 3, type: :uint64, json_name: "boardHeight")
  field(:server_tickrate_ms, 4, type: :uint64, json_name: "serverTickrateMs")
  field(:game_timeout_ms, 5, type: :uint64, json_name: "gameTimeoutMs")
  field(:map_shrink_wait_ms, 6, type: :uint64, json_name: "mapShrinkWaitMs")
  field(:map_shrink_interval, 7, type: :uint64, json_name: "mapShrinkInterval")
  field(:out_of_area_damage, 8, type: :uint64, json_name: "outOfAreaDamage")
  field(:use_proxy, 9, type: :string, json_name: "useProxy")
  field(:map_shrink_minimum_radius, 10, type: :uint64, json_name: "mapShrinkMinimumRadius")
  field(:spawn_loot_interval_ms, 11, type: :uint64, json_name: "spawnLootIntervalMs")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:board_size, 1,
    type: DarkWorldsServer.Communication.Proto.BoardSize,
    json_name: "boardSize"
  )

  field(:server_tickrate_ms, 2, type: :uint64, json_name: "serverTickrateMs")
  field(:game_timeout_ms, 3, type: :uint64, json_name: "gameTimeoutMs")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.BoardSize do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:width, 1, type: :float)
  field(:height, 2, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.CharacterConfigItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:Name, 1, type: :string)
  field(:Id, 2, type: :string)
  field(:Active, 3, type: :string)
  field(:Class, 4, type: :string)
  field(:Faction, 5, type: :string)
  field(:BaseSpeed, 6, type: :string)
  field(:SkillBasic, 7, type: :string)
  field(:SkillActive1, 8, type: :string)
  field(:SkillActive2, 9, type: :string)
  field(:SkillDash, 10, type: :string)
  field(:SkillUltimate, 11, type: :string)
  field(:BodySize, 12, type: :string)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.CharacterConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:Items, 1, repeated: true, type: DarkWorldsServer.Communication.Proto.CharacterConfigItem)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.SkillsConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:Items, 1, repeated: true, type: DarkWorldsServer.Communication.Proto.SkillConfigItem)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.SkillConfigItem do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:Name, 1, type: :string)
  field(:Cooldown, 2, type: :string)
  field(:Damage, 3, type: :string)
  field(:Duration, 4, type: :string)
  field(:OldProjectile, 5, type: :string)
  field(:SkillRange, 6, type: :string)
  field(:Par1, 7, type: :string)
  field(:Par1Desc, 8, type: :string)
  field(:Par2, 9, type: :string)
  field(:Par2Desc, 10, type: :string)
  field(:Par3, 11, type: :string)
  field(:Par3Desc, 12, type: :string)
  field(:Par4, 13, type: :string)
  field(:Par4Desc, 14, type: :string)
  field(:Par5, 15, type: :string)
  field(:Par5Desc, 16, type: :string)
  field(:Angle, 17, type: :string)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.ServerGameSettings do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:runner_config, 1,
    type: DarkWorldsServer.Communication.Proto.RunnerConfig,
    json_name: "runnerConfig"
  )

  field(:character_config, 2,
    type: DarkWorldsServer.Communication.Proto.CharacterConfig,
    json_name: "characterConfig"
  )

  field(:skills_config, 3,
    type: DarkWorldsServer.Communication.Proto.SkillsConfig,
    json_name: "skillsConfig"
  )

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.OldProjectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :uint64)
  field(:position, 2, type: DarkWorldsServer.Communication.Proto.OldPosition)
  field(:direction, 3, type: DarkWorldsServer.Communication.Proto.RelativePosition)
  field(:speed, 4, type: :float)
  field(:range, 5, type: :float)
  field(:player_id, 6, type: :uint64, json_name: "playerId")
  field(:damage, 7, type: :uint32)
  field(:remaining_ticks, 8, type: :sint64, json_name: "remainingTicks")

  field(:projectile_type, 9,
    type: DarkWorldsServer.Communication.Proto.ProjectileType,
    json_name: "projectileType",
    enum: true
  )

  field(:status, 10, type: DarkWorldsServer.Communication.Proto.ProjectileStatus, enum: true)
  field(:last_attacked_player_id, 11, type: :uint64, json_name: "lastAttackedPlayerId")
  field(:pierce, 12, type: :bool)
  field(:skill_name, 13, type: :string, json_name: "skillName")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.MillisTime do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:high, 1, type: :uint64)
  field(:low, 2, type: :uint64)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.LootPackage do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:id, 1, type: :uint64)
  field(:position, 2, type: DarkWorldsServer.Communication.Proto.OldPosition)

  field(:loot_type, 3,
    type: DarkWorldsServer.Communication.Proto.LootType,
    json_name: "lootType",
    enum: true
  )

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.Config do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:characters, 1, repeated: true, type: DarkWorldsServer.Communication.Proto.GameCharacter)
  field(:effects, 2, repeated: true, type: DarkWorldsServer.Communication.Proto.GameEffect)
  field(:game, 3, type: DarkWorldsServer.Communication.Proto.GameStateConfig)
  field(:loots, 4, repeated: true, type: DarkWorldsServer.Communication.Proto.GameLoot)
  field(:projectiles, 5, repeated: true, type: DarkWorldsServer.Communication.Proto.GameProjectile)
  field(:skills, 6, repeated: true, type: DarkWorldsServer.Communication.Proto.GameSkill)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameStateConfig do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:width, 1, type: :float)
  field(:height, 2, type: :float)

  field(:map_modification, 3,
    type: DarkWorldsServer.Communication.Proto.MapModification,
    json_name: "mapModification"
  )

  field(:loot_interval_ms, 4, type: :uint64, json_name: "lootIntervalMs")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.MapModification do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:modification, 1, type: DarkWorldsServer.Communication.Proto.Modification)
  field(:starting_radius, 2, type: :float, json_name: "startingRadius")
  field(:minimum_radius, 3, type: :float, json_name: "minimumRadius")
  field(:max_radius, 4, type: :float, json_name: "maxRadius")

  field(:outside_radius_effects, 5,
    repeated: true,
    type: DarkWorldsServer.Communication.Proto.GameEffect,
    json_name: "outsideRadiusEffects"
  )

  field(:inside_radius_effects, 6,
    repeated: true,
    type: DarkWorldsServer.Communication.Proto.GameEffect,
    json_name: "insideRadiusEffects"
  )

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.Modification do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:modifier, 1, type: DarkWorldsServer.Communication.Proto.ModifierType, enum: true)
  field(:value, 2, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameLoot do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:size, 2, type: :float)
  field(:effects, 3, repeated: true, type: DarkWorldsServer.Communication.Proto.GameEffect)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameProjectile do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:base_damage, 2, type: :uint64, json_name: "baseDamage")
  field(:base_speed, 3, type: :float, json_name: "baseSpeed")
  field(:base_size, 4, type: :float, json_name: "baseSize")
  field(:remove_on_collision, 5, type: :bool, json_name: "removeOnCollision")

  field(:on_hit_effect, 6,
    repeated: true,
    type: DarkWorldsServer.Communication.Proto.GameEffect,
    json_name: "onHitEffect"
  )

  field(:max_distance, 7, type: :float, json_name: "maxDistance")
  field(:duration_ms, 8, type: :float, json_name: "durationMs")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameCharacter.SkillsEntry do
  @moduledoc false

  use Protobuf, map: true, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:key, 1, type: :string)
  field(:value, 2, type: DarkWorldsServer.Communication.Proto.GameSkill)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameCharacter do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:active, 2, type: :bool)
  field(:base_speed, 3, type: :float, json_name: "baseSpeed")
  field(:base_size, 4, type: :float, json_name: "baseSize")
  field(:base_health, 5, type: :uint64, json_name: "baseHealth")

  field(:skills, 6,
    repeated: true,
    type: DarkWorldsServer.Communication.Proto.GameCharacter.SkillsEntry,
    map: true
  )

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameSkill do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: :string)
  field(:cooldown_ms, 2, type: :uint64, json_name: "cooldownMs")
  field(:is_passive, 3, type: :bool, json_name: "isPassive")
  field(:mechanics, 4, repeated: true, type: DarkWorldsServer.Communication.Proto.Mechanic)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.Mechanic do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:name, 1, type: DarkWorldsServer.Communication.Proto.MechanicType, enum: true)
  field(:effects, 2, repeated: true, type: DarkWorldsServer.Communication.Proto.GameEffect)
  field(:damage, 3, type: :uint64)
  field(:range, 4, type: :float)
  field(:cone_angle, 5, type: :uint64, json_name: "coneAngle")

  field(:on_hit_effects, 6,
    repeated: true,
    type: DarkWorldsServer.Communication.Proto.GameEffect,
    json_name: "onHitEffects"
  )

  field(:projectile, 7, type: DarkWorldsServer.Communication.Proto.GameProjectile)
  field(:count, 8, type: :uint64)
  field(:duration_ms, 9, type: :uint64, json_name: "durationMs")
  field(:max_range, 10, type: :float, json_name: "maxRange")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameEffect.Duration do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:type, 1, type: :string)
  field(:duration_ms, 2, type: :uint64, json_name: "durationMs")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameEffect.Periodic do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:type, 1, type: :string)
  field(:instant_application, 2, type: :string, json_name: "instantApplication")
  field(:interval_ms, 3, type: :uint64, json_name: "intervalMs")
  field(:trigger_count, 4, type: :uint64, json_name: "triggerCount")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameEffect do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:effect_type, 0)

  field(:name, 1, type: :string)
  field(:simple_type, 2, type: :string, json_name: "simpleType", oneof: 0)

  field(:duration_type, 3,
    type: DarkWorldsServer.Communication.Proto.GameEffect.Duration,
    json_name: "durationType",
    oneof: 0
  )

  field(:periodic_type, 4,
    type: DarkWorldsServer.Communication.Proto.GameEffect.Periodic,
    json_name: "periodicType",
    oneof: 0
  )

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.Move do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:angle, 1, type: :float)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.UseSkill do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:skill, 1, type: :string)
  field(:angle, 2, type: :float)
  field(:auto_aim, 3, type: :bool, json_name: "autoAim")
  field(:target_x, 4, type: :float, json_name: "targetX")
  field(:target_y, 5, type: :float, json_name: "targetY")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.UseInventory do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  field(:inventory_at, 1, type: :uint64, json_name: "inventoryAt")

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

defmodule DarkWorldsServer.Communication.Proto.GameAction do
  @moduledoc false

  use Protobuf, syntax: :proto3, protoc_gen_elixir_version: "0.12.0"

  oneof(:action_type, 0)

  field(:move, 1, type: DarkWorldsServer.Communication.Proto.Move, oneof: 0)

  field(:use_skill, 2,
    type: DarkWorldsServer.Communication.Proto.UseSkill,
    json_name: "useSkill",
    oneof: 0
  )

  field(:use_inventory, 3,
    type: DarkWorldsServer.Communication.Proto.UseInventory,
    json_name: "useInventory",
    oneof: 0
  )

  field(:timestamp, 4, type: :int64)

  def transform_module(), do: DarkWorldsServer.Communication.ProtoTransform
end

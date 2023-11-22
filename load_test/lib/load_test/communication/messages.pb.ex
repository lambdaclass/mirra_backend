defmodule LoadTest.Communication.Proto.GameEventType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:STATE_UPDATE, 0)
  field(:PING_UPDATE, 1)
  field(:PLAYER_JOINED, 2)
  field(:GAME_FINISHED, 3)
  field(:INITIAL_POSITIONS, 4)
  field(:SELECTED_CHARACTER_UPDATE, 5)
  field(:FINISH_CHARACTER_SELECTION, 6)
end

defmodule LoadTest.Communication.Proto.Status do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:ALIVE, 0)
  field(:DEAD, 1)
end

defmodule LoadTest.Communication.Proto.Action do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

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

defmodule LoadTest.Communication.Proto.Direction do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:DIRECTION_UNSPECIFIED, 0)
  field(:UP, 1)
  field(:DOWN, 2)
  field(:LEFT, 3)
  field(:RIGHT, 4)
end

defmodule LoadTest.Communication.Proto.PlayerAction do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

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

defmodule LoadTest.Communication.Proto.PlayerEffect do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

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

defmodule LoadTest.Communication.Proto.LobbyEventType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:TYPE_UNSPECIFIED, 0)
  field(:CONNECTED, 1)
  field(:PLAYER_ADDED, 2)
  field(:GAME_STARTED, 3)
  field(:PLAYER_COUNT, 4)
  field(:START_GAME, 5)
  field(:PLAYER_REMOVED, 6)
end

defmodule LoadTest.Communication.Proto.ProjectileType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:BULLET, 0)
  field(:DISARMING_BULLET, 1)
end

defmodule LoadTest.Communication.Proto.ProjectileStatus do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:ACTIVE, 0)
  field(:EXPLODED, 1)
end

defmodule LoadTest.Communication.Proto.LootType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:LOOT_TYPE_UNSPECIFIED, 0)
  field(:LOOT_HEALTH, 1)
end

defmodule LoadTest.Communication.Proto.GameEvent.SelectedCharactersEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: :string)
end

defmodule LoadTest.Communication.Proto.GameEvent do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:type, 1, type: LoadTest.Communication.Proto.GameEventType, enum: true)
  field(:players, 2, repeated: true, type: LoadTest.Communication.Proto.Player)
  field(:latency, 3, type: :uint64)
  field(:projectiles, 4, repeated: true, type: LoadTest.Communication.Proto.Projectile)
  field(:player_joined_id, 5, type: :uint64, json_name: "playerJoinedId")
  field(:player_joined_name, 6, type: :string, json_name: "playerJoinedName")
  field(:winner_player, 7, type: LoadTest.Communication.Proto.Player, json_name: "winnerPlayer")

  field(:selected_characters, 8,
    repeated: true,
    type: LoadTest.Communication.Proto.GameEvent.SelectedCharactersEntry,
    json_name: "selectedCharacters",
    map: true
  )

  field(:player_timestamp, 9, type: :int64, json_name: "playerTimestamp")
  field(:server_timestamp, 10, type: :int64, json_name: "serverTimestamp")
  field(:killfeed, 11, repeated: true, type: LoadTest.Communication.Proto.KillEvent)
  field(:playable_radius, 12, type: :uint64, json_name: "playableRadius")

  field(:shrinking_center, 13,
    type: LoadTest.Communication.Proto.Position,
    json_name: "shrinkingCenter"
  )

  field(:loots, 14, repeated: true, type: LoadTest.Communication.Proto.LootPackage)
end

defmodule LoadTest.Communication.Proto.PlayerCharacter do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:character_name, 2, type: :string, json_name: "characterName")
end

defmodule LoadTest.Communication.Proto.Player.EffectsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:key, 1, type: :uint64)
  field(:value, 2, type: LoadTest.Communication.Proto.EffectInfo)
end

defmodule LoadTest.Communication.Proto.Player do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:health, 2, type: :sint64)
  field(:position, 3, type: LoadTest.Communication.Proto.Position)
  field(:status, 4, type: LoadTest.Communication.Proto.Status, enum: true)
  field(:action, 5, type: LoadTest.Communication.Proto.PlayerAction, enum: true)
  field(:aoe_position, 6, type: LoadTest.Communication.Proto.Position, json_name: "aoePosition")
  field(:kill_count, 7, type: :uint64, json_name: "killCount")
  field(:death_count, 8, type: :uint64, json_name: "deathCount")

  field(:basic_skill_cooldown_left, 9,
    type: LoadTest.Communication.Proto.MillisTime,
    json_name: "basicSkillCooldownLeft"
  )

  field(:skill_1_cooldown_left, 10,
    type: LoadTest.Communication.Proto.MillisTime,
    json_name: "skill1CooldownLeft"
  )

  field(:skill_2_cooldown_left, 11,
    type: LoadTest.Communication.Proto.MillisTime,
    json_name: "skill2CooldownLeft"
  )

  field(:skill_3_cooldown_left, 12,
    type: LoadTest.Communication.Proto.MillisTime,
    json_name: "skill3CooldownLeft"
  )

  field(:skill_4_cooldown_left, 13,
    type: LoadTest.Communication.Proto.MillisTime,
    json_name: "skill4CooldownLeft"
  )

  field(:character_name, 14, type: :string, json_name: "characterName")

  field(:effects, 15,
    repeated: true,
    type: LoadTest.Communication.Proto.Player.EffectsEntry,
    map: true
  )

  field(:direction, 16, type: LoadTest.Communication.Proto.RelativePosition)
  field(:body_size, 17, type: :float, json_name: "bodySize")
end

defmodule LoadTest.Communication.Proto.EffectInfo do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:ends_at, 1, type: LoadTest.Communication.Proto.MillisTime, json_name: "endsAt")
  field(:caused_by, 2, type: :uint64, json_name: "causedBy")
end

defmodule LoadTest.Communication.Proto.KillEvent do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:killed_by, 1, type: :uint64, json_name: "killedBy")
  field(:killed, 2, type: :uint64)
end

defmodule LoadTest.Communication.Proto.Position do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:x, 1, type: :uint64)
  field(:y, 2, type: :uint64)
end

defmodule LoadTest.Communication.Proto.RelativePosition do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:x, 1, type: :float)
  field(:y, 2, type: :float)
end

defmodule LoadTest.Communication.Proto.ClientAction do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:action, 1, type: LoadTest.Communication.Proto.Action, enum: true)
  field(:direction, 2, type: LoadTest.Communication.Proto.Direction, enum: true)
  field(:position, 3, type: LoadTest.Communication.Proto.RelativePosition)

  field(:move_delta, 4,
    type: LoadTest.Communication.Proto.RelativePosition,
    json_name: "moveDelta"
  )

  field(:target, 5, type: :sint64)
  field(:timestamp, 6, type: :int64)

  field(:player_character, 7,
    type: LoadTest.Communication.Proto.PlayerCharacter,
    json_name: "playerCharacter"
  )
end

defmodule LoadTest.Communication.Proto.LobbyEvent do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:type, 1, type: LoadTest.Communication.Proto.LobbyEventType, enum: true)
  field(:lobby_id, 2, type: :string, json_name: "lobbyId")

  field(:player_info, 3,
    type: LoadTest.Communication.Proto.PlayerInformation,
    json_name: "playerInfo"
  )

  field(:added_player_info, 4,
    type: LoadTest.Communication.Proto.PlayerInformation,
    json_name: "addedPlayerInfo"
  )

  field(:game_id, 5, type: :string, json_name: "gameId")
  field(:player_count, 6, type: :uint64, json_name: "playerCount")

  field(:players_info, 7,
    repeated: true,
    type: LoadTest.Communication.Proto.PlayerInformation,
    json_name: "playersInfo"
  )

  field(:removed_player_info, 8,
    type: LoadTest.Communication.Proto.PlayerInformation,
    json_name: "removedPlayerInfo"
  )

  field(:game_config, 9,
    type: LoadTest.Communication.Proto.ServerGameSettings,
    json_name: "gameConfig"
  )

  field(:server_hash, 10, type: :string, json_name: "serverHash")
  field(:host_player_id, 11, type: :uint64, json_name: "hostPlayerId")
end

defmodule LoadTest.Communication.Proto.PlayerInformation do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:player_id, 1, type: :uint64, json_name: "playerId")
  field(:player_name, 2, type: :string, json_name: "playerName")
end

defmodule LoadTest.Communication.Proto.RunnerConfig do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

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
end

defmodule LoadTest.Communication.Proto.GameConfig do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:board_size, 1, type: LoadTest.Communication.Proto.BoardSize, json_name: "boardSize")
  field(:server_tickrate_ms, 2, type: :uint64, json_name: "serverTickrateMs")
  field(:game_timeout_ms, 3, type: :uint64, json_name: "gameTimeoutMs")
end

defmodule LoadTest.Communication.Proto.BoardSize do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:width, 1, type: :uint64)
  field(:height, 2, type: :uint64)
end

defmodule LoadTest.Communication.Proto.CharacterConfigItem do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

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
end

defmodule LoadTest.Communication.Proto.CharacterConfig do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:Items, 1, repeated: true, type: LoadTest.Communication.Proto.CharacterConfigItem)
end

defmodule LoadTest.Communication.Proto.SkillsConfig do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:Items, 1, repeated: true, type: LoadTest.Communication.Proto.SkillConfigItem)
end

defmodule LoadTest.Communication.Proto.SkillConfigItem do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:Name, 1, type: :string)
  field(:Cooldown, 2, type: :string)
  field(:Damage, 3, type: :string)
  field(:Duration, 4, type: :string)
  field(:Projectile, 5, type: :string)
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
end

defmodule LoadTest.Communication.Proto.ServerGameSettings do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:runner_config, 1,
    type: LoadTest.Communication.Proto.RunnerConfig,
    json_name: "runnerConfig"
  )

  field(:character_config, 2,
    type: LoadTest.Communication.Proto.CharacterConfig,
    json_name: "characterConfig"
  )

  field(:skills_config, 3,
    type: LoadTest.Communication.Proto.SkillsConfig,
    json_name: "skillsConfig"
  )
end

defmodule LoadTest.Communication.Proto.Projectile do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:position, 2, type: LoadTest.Communication.Proto.Position)
  field(:direction, 3, type: LoadTest.Communication.Proto.RelativePosition)
  field(:speed, 4, type: :uint32)
  field(:range, 5, type: :uint32)
  field(:player_id, 6, type: :uint64, json_name: "playerId")
  field(:damage, 7, type: :uint32)
  field(:remaining_ticks, 8, type: :sint64, json_name: "remainingTicks")

  field(:projectile_type, 9,
    type: LoadTest.Communication.Proto.ProjectileType,
    json_name: "projectileType",
    enum: true
  )

  field(:status, 10, type: LoadTest.Communication.Proto.ProjectileStatus, enum: true)
  field(:last_attacked_player_id, 11, type: :uint64, json_name: "lastAttackedPlayerId")
  field(:pierce, 12, type: :bool)
  field(:skill_name, 13, type: :string, json_name: "skillName")
end

defmodule LoadTest.Communication.Proto.MillisTime do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:high, 1, type: :uint64)
  field(:low, 2, type: :uint64)
end

defmodule LoadTest.Communication.Proto.LootPackage do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.12.0", syntax: :proto3

  field(:id, 1, type: :uint64)
  field(:position, 2, type: LoadTest.Communication.Proto.Position)

  field(:loot_type, 3,
    type: LoadTest.Communication.Proto.LootType,
    json_name: "lootType",
    enum: true
  )
end

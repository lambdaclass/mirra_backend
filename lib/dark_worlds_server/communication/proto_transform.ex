defmodule DarkWorldsServer.Communication.ProtoTransform do
  alias DarkWorldsServer.Communication.Proto.Attribute
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
  alias DarkWorldsServer.Communication.Proto.KillEvent
  alias DarkWorldsServer.Communication.Proto.LootPackage
  alias DarkWorldsServer.Communication.Proto.MapModification
  alias DarkWorldsServer.Communication.Proto.Mechanic
  alias DarkWorldsServer.Communication.Proto.Move
  alias DarkWorldsServer.Communication.Proto.Player, as: ProtoPlayer
  alias DarkWorldsServer.Communication.Proto.PlayerInformation, as: ProtoPlayerInformation
  alias DarkWorldsServer.Communication.Proto.Position, as: ProtoPosition
  alias DarkWorldsServer.Communication.Proto.Projectile, as: ProtoProjectile
  alias DarkWorldsServer.Communication.Proto.RelativePosition, as: ProtoRelativePosition
  alias DarkWorldsServer.Communication.Proto.UseSkill
  alias DarkWorldsServer.Communication.Proto.ZoneModification

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

  def encode(position, ProtoPosition) do
    %{x: x, y: y} = position
    %ProtoPosition{x: x, y: y}
  end

  def encode(position, ProtoRelativePosition) do
    %{x: x, y: y} = position
    %ProtoRelativePosition{x: x, y: y}
  end

  def encode(player, ProtoPlayer) do
    %ProtoPlayer{
      id: player.id,
      position: player.position,
      health: player.health,
      speed: player.speed,
      size: player.size,
      direction: player.direction,
      status: player_status_encode(player.status),
      kill_count: player.kill_count,
      death_count: player.death_count,
      # player_action_encode(player.action),
      actions: [],
      action_duration_ms: player.action_duration_ms,
      # player.cooldowns
      cooldowns: [],
      # player.effects,
      effects: [],
      character_name: player.character.name
    }
  end

  def encode(projectile, ProtoProjectile) do
    %ProtoProjectile{
      id: projectile.id,
      name: projectile.name,
      damage: projectile.damage,
      speed: projectile.speed,
      size: projectile.size,
      position: projectile.position,
      direction: projectile.direction
    }
  end

  def encode({killed_by, killed}, KillEvent) do
    %KillEvent{killed_by: killed_by, killed: killed}
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

  def encode({modifier, value}, ZoneModification) do
    %ZoneModification{
      modifier: modifier_encode(modifier),
      value: value
    }
  end

  def encode(%{modifier: modifier, attribute: attribute, value: value}, Attribute) do
    %Attribute{
      modifier: modifier_encode(modifier),
      attribute: attribute,
      value: value
    }
  end

  def encode(
        %{
          name: name,
          effect_time_type: effect_time_type,
          is_reversable: is_reversable,
          player_attributes: player_attributes,
          projectile_attributes: projectile_attributes
        },
        GameEffect
      ) do
    %GameEffect{
      name: name,
      effect_time_type: effect_time_type,
      is_reversable: is_reversable,
      player_attributes: player_attributes,
      projectile_attributes: projectile_attributes
    }
  end

  def encode(data, pstruct) do
    IO.inspect(data, label: "generic_encode: #{inspect(pstruct)}")
    raise "encode_error"
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

  def decode(config, Modifier) do
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
  def decode(value, ZoneModification) do
    value
  end

  @impl Protobuf.TransformModule
  def decode(value, Move) do
    value
  end

  @impl Protobuf.TransformModule
  def decode(position, ProtoPosition) do
    position
  end

  @impl Protobuf.TransformModule
  def decode(%ProtoRelativePosition{} = position, ProtoRelativePosition) do
    position
  end

  def decode(player, ProtoPlayer) do
    %{
      id: player.id,
      health: player.health,
      position: player.position,
      status: player_status_decode(player.status),
      action: player_action_decode(player.action),
      aoe_position: player.aoe_position,
      kill_count: player.kill_count,
      death_count: player.death_count,
      basic_skill_cooldown_left: player.basic_skill_cooldown_left,
      skill_1_cooldown_left: player.skill_1_cooldown_left,
      skill_2_cooldown_left: player.skill_2_cooldown_left,
      skill_3_cooldown_left: player.skill_3_cooldown_left,
      skill_4_cooldown_left: player.skill_4_cooldown_left,
      character_name: player.name,
      effects: player.effects,
      direction: player.direction,
      body_size: player.body_size,
      action_duration_ms: player.action_duration_ms
    }
  end

  def decode(projectile, ProtoProjectile) do
    %{
      id: projectile.id,
      position: projectile.position,
      direction: projectile.direction,
      speed: projectile.speed,
      range: projectile.range,
      player_id: projectile.player_id,
      damage: projectile.damage,
      remaining_ticks: projectile.remaining_ticks,
      projectile_type: projectile_decode(projectile.projectile_type),
      status: projectile_status_decode(projectile.status),
      last_attacked_player_id: projectile.last_attacked_player_id,
      pierce: projectile.pierce,
      skill_name: projectile.skill_name
    }
  end

  def decode(%struct{} = msg, struct) do
    Map.from_struct(msg)
  end

  ###############################
  # Helpers for transformations #
  ###############################
  defp player_status_encode(:alive), do: :STATUS_ALIVE
  defp player_status_encode(:dead), do: :STATUS_DEAD

  defp player_status_decode(:ALIVE), do: :alive
  defp player_status_decode(:DEAD), do: :dead

  def player_action_encode([]), do: []
  def player_action_encode([:attacking | tail]), do: [:ATTACKING | player_action_encode(tail)]
  def player_action_encode([:nothing | tail]), do: player_action_encode(tail)
  def player_action_encode([:attackingaoe | tail]), do: [:ATTACKING_AOE | player_action_encode(tail)]

  def player_action_encode([:startingskill1 | tail]),
    do: [:STARTING_SKILL_1 | player_action_encode(tail)]

  def player_action_encode([:startingskill2 | tail]),
    do: [:STARTING_SKILL_2 | player_action_encode(tail)]

  def player_action_encode([:startingskill3 | tail]),
    do: [:STARTING_SKILL_3 | player_action_encode(tail)]

  def player_action_encode([:startingskill4 | tail]),
    do: [:STARTING_SKILL_4 | player_action_encode(tail)]

  def player_action_encode([:executingskill1 | tail]),
    do: [:EXECUTING_SKILL_1 | player_action_encode(tail)]

  def player_action_encode([:executingskill2 | tail]),
    do: [:EXECUTING_SKILL_2 | player_action_encode(tail)]

  def player_action_encode([:executingskill3 | tail]),
    do: [:EXECUTING_SKILL_3 | player_action_encode(tail)]

  def player_action_encode([:executingskill4 | tail]),
    do: [:EXECUTING_SKILL_4 | player_action_encode(tail)]

  def player_action_encode([:moving | tail]), do: [:MOVING | player_action_encode(tail)]

  defp player_action_decode([]), do: []
  defp player_action_decode([:ATTACKING | tail]), do: [:attacking, player_action_decode(tail)]
  defp player_action_decode([:NOTHING | tail]), do: player_action_decode(tail)
  defp player_action_decode([:ATTACKING_AOE | tail]), do: [:attackingaoe, player_action_decode(tail)]
  defp player_action_decode([:STARTING_SKILL_1 | tail]), do: [:startingskill1, player_action_decode(tail)]
  defp player_action_decode([:STARTING_SKILL_2 | tail]), do: [:startingskill2, player_action_decode(tail)]
  defp player_action_decode([:STARTING_SKILL_3 | tail]), do: [:startingskill3, player_action_decode(tail)]
  defp player_action_decode([:STARTING_SKILL_4 | tail]), do: [:startingskill4, player_action_decode(tail)]
  defp player_action_decode([:EXECUTING_SKILL_1 | tail]), do: [:executingskill1, player_action_decode(tail)]
  defp player_action_decode([:EXECUTING_SKILL_2 | tail]), do: [:executingskill2, player_action_decode(tail)]
  defp player_action_decode([:EXECUTING_SKILL_3 | tail]), do: [:executingskill3, player_action_decode(tail)]
  defp player_action_decode([:EXECUTING_SKILL_4 | tail]), do: [:executingskill4, player_action_decode(tail)]
  defp player_action_decode([:MOVING | tail]), do: [:moving, player_action_decode(tail)]

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
  defp modifier_encode(:override), do: :OVERRIDE

  defp mechanic_name_encode(:hit), do: :HIT
  defp mechanic_name_encode(:simple_shoot), do: :SIMPLE_SHOOT
  defp mechanic_name_encode(:multi_shoot), do: :MULTI_SHOOT
  defp mechanic_name_encode(:give_effect), do: :GIVE_EFFECT
end

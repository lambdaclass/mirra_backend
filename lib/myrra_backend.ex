defmodule GameBackend.MyrraBackend do
  defmodule Board do
    defstruct []
  end

  defmodule Character do
    defstruct []
  end

  defmodule Game do
    defstruct [:players, :board]
  end

  defmodule Player do
    defstruct [
      :id,
      :health,
      :position,
      :status,
      :action,
      :aoe_position,
      :kill_count,
      :death_count,
      :basic_skill_cooldown_left,
      :skill_1_cooldown_left,
      :skill_2_cooldown_left,
      :skill_3_cooldown_left,
      :skill_4_cooldown_left,
      :character_name,
      :effects,
      :direction,
      :body_size
    ]
  end

  defmodule Projectile do
    defstruct [
      :id,
      :position,
      :direction,
      :speed,
      :range,
      :player_id,
      :damage,
      :remaining_ticks,
      :projectile_type,
      :status,
      :last_attacked_player_id,
      :pierce,
      :skill_name
    ]
  end

  defmodule Skill do
    defstruct []
  end

  defmodule Position do
    defstruct [:x, :y]
  end

  defmodule RelativePosition do
    defstruct [:x, :y]
  end
end

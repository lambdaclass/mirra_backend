defmodule ArenaLoadTest.Serialization.ConversionProtobuf do

  alias ArenaLoadTest.Serialization.{GameActionPB, MovePB, DirectionPB, AttackPB, AttackParametersPB}

  def get_game_move_protobuf(x, y, timestamp) do
    GameActionPB.encode(%GameActionPB{
        action_type:
          {:move,
           %MovePB{
             direction: %DirectionPB{
               x: x,
               y: y
             }
           }},
        timestamp: timestamp
      })
  end

  def get_game_attack_protobuf(skill, x, y, timestamp) do
    GameActionPB.encode(%GameActionPB{
        action_type:
          {:attack,
           %AttackPB{
             skill: skill,
             parameters: %AttackParametersPB{
               target: %DirectionPB{
                 x: x,
                 y: y
               }
             }
           }},
        timestamp: timestamp
      })
  end
end

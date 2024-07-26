defmodule BotManager.Serialization.ConversionProtobuf do
  alias BotManager.Serialization.{GameEventPB, GameActionPB, MovePB, DirectionPB, AttackPB, AttackParametersPB}

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

  def decode_game_event_protobuf(message) do
    GameEventPB.decode(message)
  end
end

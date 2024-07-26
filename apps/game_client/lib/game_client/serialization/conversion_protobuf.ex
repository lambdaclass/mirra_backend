defmodule GameClient.Serialization.ConversionProtobuf do
  alias GameClient.Serialization.{GameStatePB, GameActionPB, ToggleBotsPB, DirectionPB, GameEventPB, AttackPB, AttackParametersPB, LobbyEventPB, MovePB, UseItemPB}

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

  def get_join_game_protobuf(game_id) do
    GameStatePB.encode(%GameStatePB{
        game_id: game_id,
        players: %{},
        projectiles: %{}
      })
  end

  def get_game_use_item_protobuf(item) do
    GameActionPB.encode(%GameActionPB{
        action_type: {:use_item, %UseItemPB{item: String.to_integer(item)}}
      })
  end

  def get_toggle_bots_protobuf() do
    GameActionPB.encode(%GameActionPB{
        action_type: {:toggle_bots, %ToggleBotsPB{}}
      })
  end

  def get_direction_protobuf(direction) do
    DirectionPB.encode(%DirectionPB{
      x: direction.x,
      y: direction.y
    })
  end

  def decode_lobby_event_protobuf(message) do
    LobbyEventPB.decode(message)
  end

  def decode_game_event_protobuf(message) do
    GameEventPB.decode(message)
  end
end

# BotManager

Application to host bots for matches taking place in `arena` application

## Usage 

To generate a bot just do a `get` to the following url: `http://localhost:5000/join/:game_id/:player_id`  where:
- game_id: is the result of doing the following operation to the [`pid`](https://hexdocs.pm/elixir/processes.html)  running the game_updater instance: `self() |> :erlang.term_to_binary() |> Base58.encode()`
- player_id: is the is of the player entity assigned while the game is being created

## Communication between arena and bot manager
```mermaid
sequenceDiagram
    box  Arena
    participant GameLauncher
    participant GameUpdater
    participant GameSocketConnection
    end
    box  Bot Manager
    participant Endpoint
    participant BotGameSocketConnection
    participant BotSupervisor
    end

    GameLauncher->>GameUpdater:start(clients, missing_players) 
    GameUpdater->>Endpoint:get(join/game_id/player_id)
    Endpoint->>BotSupervisor:spawn_bot(bot_params)
    BotSupervisor->>BotGameSocketConnection:init(bot_params)
    BotGameSocketConnection->>GameSocketConnection:connect()
    loop Every 300ms
        BotGameSocketConnection->>GameSocketConnection: do_action(:move)
        GameSocketConnection->>GameUpdater:do_action()
    end
```

## Behavior
<!-- TODO implement complex behavior -->
- the bot will send a move message every 300 ms


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
    participant Arena.GameSocketHandler
    participant GameLauncher
    participant GameUpdater
    participant Sockethandler
    end
    box  Bot Manager
    participant SocketHandler
    participant Endpoint
    participant BotSupervisor
    participant BotManager.GameSocketHandler
    end

    GameLauncher->>+GameLauncher:start_by_timeout
    GameLauncher->>-Endpoint:get(join/client_id)
    Endpoint->>BotSupervisor:spawn_bot(client_id)
    BotSupervisor->>SocketHandler:init(client_id)
    SocketHandler->>+Sockethandler:connect()
    Sockethandler->>GameLauncher: send(:join)
    GameLauncher->>GameUpdater:start(clients) 
    GameUpdater->>GameLauncher:{:ok, game_state} 
    GameLauncher->>Sockethandler: send(:join_game, game_id)
    Sockethandler->>-SocketHandler:send(:binary, game_sate)
    SocketHandler->>BotSupervisor:add_bot_to_game(client_id, game_id)
    BotSupervisor->>BotManager.GameSocketHandler:init()
    BotManager.GameSocketHandler->>Arena.GameSocketHandler:connect()


    loop Every 300ms
        BotManager.GameSocketHandler->>Arena.GameSocketHandler: do_action()
        Arena.GameSocketHandler->>GameUpdater:do_action()
    end
    


```

## Behavior
<!-- TODO implement complex behavior -->
- the bot will send a move message every 300 ms


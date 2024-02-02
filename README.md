# Mirra Backend
Mirra Backend is an umbrella project that contains several apps within it.

The objective is to split the project into multiple applications (modules) based on their responsibilities. This will allow us to add decoupled modules that can be used together without having a dependency between them

To start all applications, run the following command:

```
devenv up
```

Then navigate to the following link to start a game: http://localhost:3000/board/1

Each of the applications, as mentioned in the previous paragraph, has a specific responsibility:

### Arena
This app is responsible for handling the game logic and is composed of 2 parts:

- The management of the game itself, where player connections are established, their actions are received, and events are resolved. For example, in response to a player's move event, this app receives it and communicates with the 2D physics engine to execute it. It is also responsible for sending game updates to clients.
- A 2D physics engine where entity movements are handled, and collisions between them are checked.

To run this app individually, you can use the following commands:

```
cd apps/arena/
make deps
make start
```

For more information, you can read its [documentation](apps/arena/README.md)

### Game Client
This app is a representation of the arena using simple 2D shapes and polygons that interact with each other. This provides a developer-friendly way to understand what is happening.

For now, this client is only connected to the Arena app, but it could be integrated with any other application.

To run this app individually, you can use the following commands:

```
cd apps/game_client/
make deps
make start
```
For more information, you can read its [documentation](apps/game_client/README.md)

### Future iterations
In future iterations, we will add the following apps:

- Bots
- Matchmaking
- Marketplace
- Chat
- Inventory
- Leaderboard

And some more.

# Mirra Backend
Mirra Backend is an umbrella project that contains several projects within it.

The idea is to divide the development into multiple applications based on their responsibilities and to be able to add independent modules that can be used together without interfering with the operation of others.

To start all applications, you should run the following command:
```
make start
```

After that, you should go to the following link http://localhost:3000/board/1

Each of the projects, as mentioned in the previous paragraph, has a specific responsibility:

### Arena
This project is responsible for handling the game logic and is composed of 2 parts:

- The management of the game itself, where player connections are established, their actions are received, and events are resolved. For example, in response to a player's move event, this project receives it and communicates with the 2D physics engine to execute it. It is also responsible for sending game updates to clients.
- A 2D physics engine where entity movements are handled, and collisions between them are checked.

To run this project individually, you can use the following commands:

```
cd apps/arena/
make deps
make start
```

For more information, you can read its [documentation](apps/arena/README.md)

### Game Client
This project allows visualizing the game in a simplified version of the UI, where shapes and polygons interact with each other. It provides a developer-friendly way to understand what is happening.

To run this project individually, you can use the following commands:

```
cd apps/game_client/
make deps
make start
```
For more information, you can read its [documentation](apps/game_client/README.md)


### Future iterations
In future iterations, we will add the following projects:

- Bots
- Matchmaking
- Marketplace
- Chat
- Inventory
- Leaderboard

And some more.

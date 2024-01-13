# Mirra Backend

Mirra Backend is an umbrella project that contains several apps.

## Apps

To start all apps, run:
`make start`

Then, to start a game [here](http://localhost:3000/board/1)

### Arena

Arena is a multiplayer backend for 2d and 3d games.
To start the application, you can do:
  - ```cd apps/arena/```
  - ```make deps```
  - ```make start```

For more information, you can read its [documentation](apps/arena/README.md)

### Game Client

Game Client is a web client to run the game backend in browser.
To start the application, you can do:
  - ```cd apps/game_client/```
  - ```make deps```
  - ```make start```

For more information, you can read its [documentation](apps/game_client/README.md)

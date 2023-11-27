# LoadTest

This directory contains the code we use to load test our backend architechture. The organization is as follows:

- This README will contain an explanation on how to run the load tests
- On `reports/` we'll keep track record of the times we run load tests. The methodology, results and actions taken based on it.

```bash
cd server/load_test
mix deps.get
export SERVER_HOST=localhost:4000
iex -S mix
```

You can use localhost or the IP of a server running the game backend. This is useful to run a local check but the proper approach to load testing is to run a two server setup: one for a client and one for the server. You can read more about this at [load_testing.md](../../docs/src/load_testing.md).

Inside the Elixir shell

```
LoadTest.PlayerSupervisor.spawn_players(50)
```

to create 50 players that will connect to the server and wait to be assigned a
game and then wait for it to start. Once it starts they send random commands
every 30 ms. They still receive updates form the server but those are just
ignored.

When running the load test (either locally or in a server), you might encounter a connection refused error that is related to not having enough file descriptors. To fix this you should run the following command both in the terminal session used to run the server and the one used to run the client:

```bash
# run before running iex -S mix or make run
ulimit -n 65535
```

When the game server is ran as a systemd service you might need to edit the service config. You can check [LimitNOFILE on the server setup script](./setup_game_server.sh) although it's a one time thing. You shouldn't do it every time.

## Analyzing results

If you want to see a request tracking report for every player of every game after a load test, you can run the helper function `DarkWorldsServer.Engine.RequestTracker.report/1` *on the server*. Running

```
DarkWorldsServer.RunnerSupervisor.RequestTracker.report(:game)
```

will show something like this:

```
Report of request tracking
--------------------------
total msgs: 286929
total games: 50

Details per game
------------------
<0.1220.0> =>
   total msgs: 5743
   total players: 3
<0.1296.0> =>
   total msgs: 5730
   total players: 3
```

while running

```
DarkWorldsServer.RunnerSupervisor.RequestTracker.report(:player)
```

will show something like this:

```
Report of request tracking
--------------------------
total msgs: 286929
total games: 2

Details per game
------------------
<0.1220.0> =>
   total msgs: 5743
   total players: 3
   msgs per player =>
       player 1, total msg: 1914
       player 2, total msg: 1915
       player 3, total msg: 1914
<0.1296.0> =>
   total msgs: 5730
   total players: 3
   msgs per player =>
       player 1, total msg: 1910
       player 2, total msg: 1910
       player 3, total msg: 1910
```

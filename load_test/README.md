# LoadTest

```bash
cd server/load_test
mix deps.get
export SERVER_HOST=10.150.20.186:4000
iex -S mix
```

Inside the Elixir shell

```
LoadTest.PlayerSupervisor.spawn_50_sessions()
```

to create 50 games with 3 players sending random commands every 30 ms.

If you plan on creating more than 50 sessions, first increase the file descriptor limit of your shell by doing

```bash
ulimit -n 65535
before running iex -S mix
```

If you want to see a request tracking report for every player of every game after a load test, you can run the helper function `DarkWorldsServer.Engine.RequestTracker.report/1` *on the server*. Running

```
DarkWorldsServer.Engine.RequestTracker.report(:game)
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
DarkWorldsServer.Engine.RequestTracker.report(:player)
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

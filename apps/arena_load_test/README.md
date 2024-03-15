# ArenaLoadTest

Application to load test the Arena backend implementation. It simulates *N* clients joining the game queue.

## How to do run our load tests?

```bash
# arena_server_ip is the IP of the server that's running the Arena application
# SERVER_HOST is localhost:4000 if not explicited
export SERVER_HOST=${arena_server_ip}:4000
make run
```

Inside the Elixir shell:
```elixir
# number_of_simulated_players must be a positive integer
ArenaLoadTest.SocketSupervisor.spawn_players(number_of_simulated_players)
```

This will create the requested amount of players that will connect to the server queue and wait to be assigned a
game.
Once it starts they send random game actions (such as move in some direction) every 300 ms.

## Considerations

### Amount of clients playing simultaneously
The OS running the application limits the File Descriptors per process. Here, we're opening as many clients (processes) as needed, in case we need more clients than our OS allows, we can increase it by running in a shell:
```bash
# number_of_file_descriptors is an integer that represents the amount needed
ulimit -n number_of_file_descriptors
# You can also check your current File Descriptors' limit by running the following
ulimit -n
```

### Amount of players per game
It's important to note that the Arena application defines how many players play in the same game match. If you want to increase the number of players in a game, you have to deploy the Arena application in the desired server with that configuration.

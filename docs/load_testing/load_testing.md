## Load Testing guide
The goal of load testing is to simulate a real scenario where there
are a lot of players in one server, our current goal is 1000 players by server.

Our current methodology is to use 2 servers to load test:
- The game server: where the game's server is actually running.
- The load test client: sends requests to the game server, we 
  want a dedicated load test client to avoid consumer network
  and hardware limitations.

Some things to keep in mind about load tests:
- Always write a report, and every report must go to:
  server/load_test/reports/your_report.md, this is important 
  to keep track of possible performance regressions.
- Always write down the specs + OS + config from where you're running the tests.
  For example, did you change linux's governor settings? Write it down.
  Did you test any BEAM VM flag? Keep a record of it.
- Write down every code snippet that you've used, be it Elixir, Rust or bash commands,
  if you think it's obvious, write it down just in case.
- Track records of the parameters you've used for the tests, eg: Player Amount,
  were there bots enabled? etc.
- Use text or pictures for reports, videos only if there are UX (i.e. gameplay) issues.
- Use multiple sources of truth and data, like htop, New Relic, erlang's etop/fprop.
- Feel free to experiment a bit, certain VM flags can improve or hinder performance,
  if you find improvements.
- It's important for load tests to be reproducible.

### Setup
I recommend you add each server ip to your ~/.ssh/config file to avoid confusions, like this:
First, open a terminal and run: 
```bash 
 open ~/.ssh/config
``` 
And paste this:
```conf 
Host myrra_load_test_client
  Hostname client_ip

Host myrra_load_test_server
  Hostname game_ip
```

### Game Server Setup
1. Check you can log into it with ssh: 
   ```sh
   ssh myuser@myrra_load_test_server
   ```
2. If it's not already there exit, copy the script on this repo under
   `game_backend/load_test/setup_game_server.sh` it clones the game server and compiles it:
   ```sh
   scp /path_go_game_backend/game_backend/load_test/setup_game_server.sh myrra_load_test_server:/user/setup_game_server.sh
   ```
   Then relog (step 1) and relog into the server 
   `setup_game_server` can also take a branch name as an argument. So if you want to run the load test on an specific branch, you can instead do:
   ```sh
   chmod +x ./setup_game_server.sh && ./setup_game_server.sh <BRANCH_NAME_TO_TEST>
   ```

3. Now you can start the game server with: 
```sh
export $(cat .env | xargs) && cd game_backend && MIX_ENV=prod iex -S mix phx.server
```
   You can check the logs with `journalctl -xefu curse_of_myrra`.
   From now on, you can just use: 
```sh
MIX_ENV=prod iex -S mix phx.server
```
   
4. Make sure to disable hyperthreading, if using an x86 CPU:
```sh
# If active, this returns 1
cat /sys/devices/system/cpu/smt/active
# Turn off hyperthreading
echo off | sudo tee /sys/devices/system/cpu/smt/control
```
One way of checking this, besides the command above,
is to open htop, you should see the virtual cores as 'offline'.

### Load Test Client setup
1. Log into it with ssh: 
   ```sh
   ssh myuser@myrra_load_test_client
   ```
2. If not already there, copy this repo's script under `server/load_test/setup_load_client.sh`
   and run it:
   ```sh
   scp /path_go_game_backend/game_backend/load_test/setup_load_client.sh myrra_load_test_server:/user/setup_load_client.sh
   ```
   `setup_load_client` can also take a branch name as an argument. So if you want to run the load test client from a specific branch, you can instead do:
   ```sh
   ./setup_load_client.sh <BRANCH_NAME_TO_TEST>
   ```
3. Set this env variable: `export SERVER_HOST=game_server_ip:game_server_port`.
   Where `game_server_ip` is the ip of the load test server, and `game_server_port`,
   the corresponding port.
4. Run:
   ```sh
       cd ./curse_of_myrra/server/load_test/ && iex -S mix 
   ``` 
   this drops you into an Elixir shell from which you'll run the load tests.
5. From the elixir shell, start the load test with:
   ```elixir
   LoadTest.PlayerSupervisor.spawn_players(number_of_players, play_time_in_seconds)
   ``` 


### Useful tools
- Htop: To monitor CPU Usage, usually installed on Linux distributions and Mac.
- Glances: Like htop but more friendly and has some more useful data,
  like Net Usage.
- Fprof: To generate a visual tree of function calls,
  (here's how to use it)[https://blog.appsignal.com/2022/04/26/using-profiling-in-elixir-to-improve-performance.html],
  you'll then (erlgrind)[https://github.com/isacssouza/erlgrind] to interpret the data,
  and install (qcachegrind)[https://formulae.brew.sh/formula/qcachegrind].
- Etop: Like unix's htop, but for erlang, on an Elixir Shell start it with:
```elixir
    Etop.start(file: "/tmp/etop.exs", interval: 2000)
```

# Load Testing guide
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

## First Step: Setup SSH
I recommend you add each server ip to your ~/.ssh/config file to avoid confusions, like this:
First, open a terminal and run: 
```bash 
 open ~/.ssh/config
``` 
And paste this:
```conf 
Host myrra_load_test_client
  Hostname client_ip
  User user

Host myrra_load_test_server
  Hostname game_ip
  User user
```

(You don't have to literally put `user` there. Put the appropiate user based on the server you'll be using).

## Second Step : Load Test Server First Time Setup

1. Check you can log into it with ssh: 
   ```sh
   ssh myuser@myrra_load_test_server
   ```
2. Then run `exit` and copy the script on this repo under
   `load_test/setup_game_server.sh` it installs all dependencies, clones the game server and compiles it:
   ```sh
   scp load_test/setup_game_server.sh myrra_load_test_server:setup_game_server.sh && ssh myuser@myrra_load_test_server
   ```

   From now on, you'll be running commands from the load test server's terminal. To return to your terminal you can run `exit`

3. Set the needed env variables on the $HOME/.env file.
   First create it: 
```sh
cat <<EOF > ~/.env
PHX_HOST=
PHX_SERVER=true
SECRET_KEY_BASE=
DATABASE_URL=ecto://postgres:postgrespassword@localhost/dark_worlds_server
EOF
```
   And then fill it. Lastly after that you also have to export those variables with:

    ```bash
    export $(cat ~/.env | xargs)
    ```
4. Run `setup_game_server.sh` with:
   ```sh
   chmod +x ./setup_game_server.sh && sudo ./setup_game_server.sh
   ```

   This installs dependencies, clones the repo and compiles the app *on the main branch*

## Third Step : Load Test Runner First Time Setup
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

## Fourth Step : Starting the load test server

1. Make sure to disable hyperthreading, if using an x86 CPU:
```sh
# If active, this returns 1
cat /sys/devices/system/cpu/smt/active
# Turn off hyperthreading
echo off | sudo tee /sys/devices/system/cpu/smt/control
```
One way of checking this, besides the command above,
is to open htop, you should see the virtual cores as 'offline'.

2. Run this command to increase the file descriptor amount.
```bash
ulimit -n 65000
```

3. Export the variables defined at `~/.env`
    ```bash
    export $(cat ~/.env | xargs)
    ```
4. Set the env variables for newrelic:

    ```bash
    export NEW_RELIC_APP_NAME=
    export NEW_RELIC_LICENSE_KEY=
    ```

    You will have to ask for them

5. Now you can start the game server with: 
```sh
cd game_backend && MIX_ENV=prod iex -S mix phx.server
```
   You can check the logs with `journalctl -xefu curse_of_myrra`.
   From now on, you can just use: 
```sh
MIX_ENV=prod iex -S mix phx.server
```

## Fifth Step : Starting the load test runner

1. Set this env variable: `export SERVER_HOST=game_server_ip:game_server_port`.
   Where `game_server_ip` is the ip of the load test server, and `game_server_port`,
   the corresponding port.
2. Run this command to increase the file descriptor amount.
```bash
ulimit -n 65000
```
3. Run:
   ```sh
       cd ./curse_of_myrra/server/load_test/ && iex -S mix 
   ``` 
   this drops you into an Elixir shell from which you'll run the load tests.
4. From the elixir shell, start the load test with:
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

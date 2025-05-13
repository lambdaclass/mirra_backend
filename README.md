# Mirra Backend
Mirra Backend is an umbrella project that contains several apps within it.

The objective is to split the project into multiple applications (modules) based on their responsibilities. This will allow us to add decoupled modules that can be used together without having a dependency between them.

## Table of Contents
- [Setup Guide](#setup-guide)
- [Applications](#applications)
- [Performance](#performance)

## Setup Guide

This guide will help you install the necessary tools and run the backend services for the Mirra project.

### 1. Install Nix

Run the following command in the terminal:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

The installer will ask you for the sudo password, and then print the details about what steps it will perform to install Nix. You have to accept this to proceed with the installation

Make sure there weren't any errors during the installation and, if there are none, close the shell and start a new one.

To test if Nix generally works, just run GNU hello or any other package:

```bash
nix run nixpkgs#hello
```

If you see:

```bash
> Hello, world!
```

Then Nix has been installed correctly. For more details, check the [Nixcademy installation guide](https://nixcademy.com).

### 2. Install Devenv

Nix MUST be installed before devenv (devenv depends on nix).  
The following command installs devenv:

```bash
nix-env -if https://install.devenv.sh/latest
```

For devenv to manage caches for you, add yourself to trusted-users in nix conf:

```bash
sudo su -
vim /etc/nix/nix.custom.conf
```

Inside Vim, press `i` to edit and add the following line, replacing `your-user` with your actual username:

```bash
trusted-users = root your-user
```


Save and exit Vim (`Esc`, then `:wq` and Enter).  

- If you don't know your user, you can type the following in a terminal:

```bash
whoami
```

Then after you're done with Vim, You have to restart the nix-daemon

```bash
sudo launchctl kickstart -k system/systems.determinate.nix-daemon
```

### 3. Clone the repository

```bash
git clone https://github.com/lambdaclass/mirra_backend.git
```

### 4. Install the Elixir package manager

```bash
cd mirra_backend
devenv shell
mix archive.install github hexpm/hex branch latest
```

### 5. Install Protobuf

Protobuf is used to serialize WebSocket messages. Install it with:

```bash
brew install protobuf
mix escript.install hex protobuf
```

⚠️ **Note:** If you used `brew`, add the `escripts` folder to your `$PATH` (follow the instructions after installation).

### 6. Install JS Protobuf for the client

```bash
cd assets
npm install google-protobuf
npm install -g protoc-gen-js
cd ..
```

### 7. Start the applications

To build and run all the applications, run the following command:

From `mirra_backend/` folder, run:

```bash
devenv up
```

If you want to have access to the Elixir console, instead do:

```bash
devenv shell postgres
```

Then in another terminal:

```bash
devenv shell
make start
```

⚠️ **Note:** Make sure you’ve run `devenv up` at least once before executing these commands.

## Applications

- [Arena](#arena)
- [Game Client](#game-client)
- [Gateway](#gateway)
- [ChampionsOfMirra](#championsofmirra)
- [GameBackend](#configurator)

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

### Gateway
Receives messages via websocket and routes them to the corresponding game's application.

### ChampionsOfMirra
Application for Champions Of Mirra game. Has modules for:
  - Battle - Simulates battles. For now, only allows fights between a user and a level from the campaign.
  - Campaigns - Creates a campaign with customizable difficulty, in the shape of 5 units per level.
  - Items - Handles logic for Items. Consumes from the Items app for general items logic.
  - Units - Handles logic for Units. Consumes from the Units app for general items logic.
  - Users - Handles logic for Users. Consumes from the Users app for general items logic.

### GameBackend
Persistance layer and shared logic:
- Users logic that's general among all games. This module is quite incomplete for now, since users are only made of a unique username.
- Units logic that's general among all games. Defines the schemas for the characters of every game. These act like templates for Units, which are instances of them tied to a user or a campaign level.
- Items logic that's general among all games. Defines the schemas for the item templates of every game. These act like templates for Items, which are instances of them that belong to a user and can be equipped to a unit.

What's important to note is that each game's application decides how to use the functionalities these applications have. For example, take a look at how Champions of Mirra implements `Champions.Units.select_unit/3` and `unselect_unit/2`. For the first one, we have some rules on how and when a unit can be selected, so we check they are met before calling the `GameBackend` app. For the second one, we don't care for the context it is called in, so we just call `GameBackend.Units.unselect_unit/2` instantly. Another game might have different requirements for unit selection/unselection, and it would be handled in its own `NewGame.Units` module.

### Configurator
This app is in charge of the configurations. Think either full game config or feature flags for A/B testing

In it you will be able to create new configurations and decide the default version to be used. Configurations are inmutable to allow rollbacks and easier A/B testing, you can always create a new one based on the default one or one in particular

[Read more](/apps/configurator/README.md)

### Future iterations
In future iterations, we will add the following apps:

- Bots
- Matchmaking
- Marketplace
- Chat
- Inventory
- Leaderboard

And some more.

## Performance

We perform load tests to evaluate how many games and players our servers can handle. Our load test setup consists of a load test runner server and an arena server. We launch a number of load test clients (players) from the load test app, which attempt to join games hosted by the arena server. We also control how many of those players are placed into the same game. Matches are filled with bots until they reach the required player count, which is currently 12 players (clients + bots) per match. It’s important to note that bots run inside the same Arena application as the game matches.

Using this setup, we evaluated three different scenarios. The results below are from one-hour load test sessions:

- Games with 12 load test clients (no bots scenario):
  - Supported 75 concurrent games, totaling 900 load test clients.
  - Bandwidth reached the 1 Gbps limit.
  - [Loadtest Snapshot](https://grafana.championsofmirra.com/dashboard/snapshot/OmIYoHxi1kWnhBSec2YbWiJ3aLuxoiY8?orgId=1&from=2025-05-13T16:10:00.000Z&to=2025-05-13T17:10:59.000Z&timezone=browser&refresh=5s)
- Games with 6 load test clients and 6 bots:
  - Supported 150 concurrent games, totaling 900 load test clients and 900 bots.
  - Bandwidth reached the 1 Gbps limit.
  - [Loadtest Snapshot](https://grafana.championsofmirra.com/dashboard/snapshot/Kvx7Jyhm5ThB6sa8B6eS0F27bQKDucOU)
- Games with 1 load test client and 11 bots (solo client scenario):
  - Supported around concurrent 350 games, totaling 350 load test clients and 3850 bots.
  - CPU usage reached 100% and became the limiting factor.
  - [Loadtest Snapshot](https://grafana.championsofmirra.com/dashboard/snapshot/p86A4TiHhxOsMmQFJrO7XPeBI1reVix3?orgId=1&from=2025-05-09T16:07:15.000Z&to=2025-05-09T17:25:15.000Z&timezone=browser&refresh=5s)

### Specs of the servers used for load tests

<details>
<summary>Arena server specs</summary>

```bash
🔹 Hostname & OS Info:
Operating System: Debian GNU/Linux 12 (bookworm)
          Kernel: Linux 6.1.0-28-amd64
    Architecture: x86-64

🔹 CPU Information:
CPU(s):                               64
On-line CPU(s) list:                  0-63
Vendor ID:                            AuthenticAMD
Model name:                           AMD EPYC 7502P 32-Core Processor
Thread(s) per core:                   2
Core(s) per socket:                   32
Socket(s):                            1
CPU(s) scaling MHz:                   63%
NUMA node0 CPU(s):                    0-63

🔹 Total Memory (RAM):
125.65 GB

🔹 Filesystem Disk Usage:
Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p3  875G  5.1G  825G   1% /
```
</details>

<details>
<summary>Load Test runner server specs (virtualized)</summary>

```bash
🔹 Hostname & OS Info:
Operating System: Debian GNU/Linux 12 (bookworm)
          Kernel: Linux 6.1.0-31-amd64
    Architecture: x86-64

🔹 CPU Information:
CPU(s):                               4
On-line CPU(s) list:                  0-3
Vendor ID:                            GenuineIntel
Model name:                           Intel Xeon Processor (Skylake, IBRS, no TSX)
Thread(s) per core:                   1
Core(s) per socket:                   4
Socket(s):                            1
NUMA node0 CPU(s):                    0-3

🔹 Total Memory (RAM):
7.57 GB

🔹 Filesystem Disk Usage:
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        75G  6.4G   66G   9% /
```
</details>

### Next tests

#### Increase server network bandwidth

It'd be ideal in the future to be able to deploy and run a loadtest without bandwidth bottleneck. This could be achieved by increasing the server’s network bandwidth capacity.

#### Reducing bandwidth consumption

Currently each client consumes 1mbps. Even by having 10gbps we wouldn't stand 10k users on a single server. We should try to reduce the size of our updates (our diff algorithm is still a bit naive, so we can definitely do some improvements over there).

#### Reduce bots messages: ETS Tables

We recently [fixed a bug](https://github.com/lambdaclass/mirra_backend/pull/1195) that prevented us from supporting more than 100 games (110 players + 1100 bots) before the gameplay started to degrade.
The issue was caused by the GameUpdater process sending 231,648 bytes to each bot process every 30 milliseconds. We discovered that 217,336 of those bytes were redundant—bots didn’t need that data more than once. This inefficiency pushed us closer to real hardware bottlenecks, particularly in CPU and bandwidth usage.

While looking for alternatives, we changed how the GameUpdater broadcasts information to bots. Instead of sending the game state via PubSub (as we do for normal clients/players), we now create an ETS table per match. The game state diffs are inserted into this table, and bots fetch the data whenever the updater instructs them to do so (via PubSub).

We ran a load test with 1 player and 11 bots per match and observed no performance differences compared to main.
  - Here's the used code: https://github.com/lambdaclass/mirra_backend/pull/1203

Next, we plan to test this further by completely removing PubSub for bots, allowing them to fetch new states on demand. We'll also experiment with having them fetch state less frequently than the tick rate (e.g., intervals > 30ms). These tests will help us gain deeper insight into how we can continue improving backend bot performance.

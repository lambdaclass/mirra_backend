# Mirra Backend
Mirra Backend is an umbrella project that contains several apps within it.

The objective is to split the project into multiple applications (modules) based on their responsibilities. This will allow us to add decoupled modules that can be used together without having a dependency between them.

## Setup Guide

This guide will help you install the necessary tools and run the backend services for the Mirra project.

## 1. Install Nix

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

## 2. Install Devenv

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

## 3. Clone the repository

```bash
git clone https://github.com/lambdaclass/mirra_backend.git
```

## 4. Install the Elixir package manager

```bash
cd mirra_backend
devenv shell
mix archive.install github hexpm/hex branch latest
```

## 5. Install Protobuf

Protobuf is used to serialize WebSocket messages. Install it with:

```bash
brew install protobuf
mix escript.install hex protobuf
```

⚠️ **Note:** If you used `brew`, add the `escripts` folder to your `$PATH` (follow the instructions after installation).

## 6. Install JS Protobuf for the client

```bash
cd assets
npm install google-protobuf
npm install -g protoc-gen-js
cd ..
```

## 7. Start the applications

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

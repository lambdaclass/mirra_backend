
# Usage: ./setup_game_server.sh <BRANCH_NAME>
# If no BRANCH_NAME is provided, defaults to main

BRANCH_NAME="$1"
BRANCH_NAME=${BRANCH_NAME:-"main"}

export MIX_ENV=prod

if [ -d "/tmp/game_backend" ]; then
  rm -rf /tmp/game_backend
fi

# Clone and compile the game.
cd /tmp
git clone git@github.com:lambdaclass/game_backend.git --branch ${BRANCH_NAME}
cd game_backend/

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix assets.deploy
mix compile
mix phx.gen.release
mix release --overwrite

rm -rf $HOME/game_backend
mv /tmp/game_backend $HOME/game_backend

$HOME/game_backend/_build/prod/rel/dark_worlds_server/bin/migrate

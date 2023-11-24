# Usage: ./setup_game_server.sh <BRANCH_NAME>
# If no BRANCH_NAME is provided, defaults to main

BRANCH_NAME="$1"
BRANCH_NAME=${BRANCH_NAME:-"main"}

export MIX_ENV=prod
cd /tmp
# # Clone and compile the game.
git clone https://github.com/lambdaclass/curse_of_myrra.git dark_worlds_server
cd dark_worlds_server
git sparse-checkout set --no-cone server
git checkout $BRANCH_NAME
cd server/

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix assets.deploy
mix compile
mix phx.gen.release
mix release --overwrite

rm -rf $USER/dark_worlds_server
mv /tmp/dark_worlds_server $HOME/dark_worlds_server

# Create a service for the gmae.
cat <<EOF > /etc/systemd/system/curse_of_myrra.service
[Unit]
Description=Curse Of Myrra server
Requires=network-online.target
After=network-online.target

[Service]
User=root
WorkingDirectory=$HOME/dark_worlds_server/server
Restart=on-failure
ExecStart=$HOME/dark_worlds_server/server/entrypoint.sh
ExecReload=/bin/kill -HUP
KillSignal=SIGTERM
EnvironmentFile=/root/.env
LimitNOFILE=65512

[Install]
WantedBy=multi-user.target
EOF

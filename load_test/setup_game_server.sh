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

cat <<EOF > /etc/systemd/system/game_backend.service
[Unit]
Description=Dark Worlds server
Requires=network-online.target
After=network-online.target

[Service]
User=root
WorkingDirectory=/root/game_backend
Restart=on-failure
ExecStart=/root/game_backend/entrypoint.sh
ExecReload=/bin/kill -HUP
KillSignal=SIGTERM
EnvironmentFile=/root/.env
LimitNOFILE=65512

[Install]
WantedBy=multi-user.target
EOF

systemctl enable game_backend

systemctl stop game_backend

/root/game_backend/_build/prod/rel/dark_worlds_server/bin/migrate

systemctl daemon-reload
systemctl start game_backend

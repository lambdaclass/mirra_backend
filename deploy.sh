#!/usr/bin/env bash
. "$HOME/.asdf/asdf.sh"
. "$HOME/.cargo/env"
set -ex

if [ -d "/tmp/game_backend" ]; then
  rm -rf /tmp/game_backend
fi

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
mv /tmp/game_backend $HOME/

cat <<EOF > $HOME/.config/systemd/user/game_backend.service
[Unit]
Description=Game Backend server
Requires=network-online.target
After=network-online.target

[Service]
User=dev
WorkingDirectory=$HOME/game_backend
Restart=on-failure
ExecStart=$HOME/game_backend/entrypoint.sh
ExecReload=/bin/kill -HUP
KillSignal=SIGTERM
EnvironmentFile=$HOME/.env
LimitNOFILE=4000

[Install]
WantedBy=multi-user.target
EOF

systemctl --user enable game_backend

cat <<EOF > $HOME/.env
PHX_HOST=${PHX_HOST}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
DATABASE_URL=${DATABASE_URL}
EOF

systemctl --user stop game_backend

$HOME/game_backend/_build/prod/rel/dark_worlds_server/bin/migrate

systemctl --user daemon-reload
systemctl --user start game_backend

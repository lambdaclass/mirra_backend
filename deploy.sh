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
mix release

rm -rf /root/game_backend
mv /tmp/game_backend /root/

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

[Install]
WantedBy=multi-user.target
EOF

systemctl enable game_backend

cat <<EOF > /root/.env
PHX_HOST=${PHX_HOST}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
DATABASE_URL=${DATABASE_URL}
EOF

systemctl stop game_backend

/root/game_backend/_build/prod/rel/game_backend/bin/migrate

systemctl daemon-reload
systemctl start game_backend

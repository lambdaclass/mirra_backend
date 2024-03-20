#!/usr/bin/env bash
set -ex

if [ -d "/tmp/mirra_backend" ]; then
	rm -rf /tmp/mirra_backend
fi

cd /tmp
git clone https://github.com/lambdaclass/mirra_backend.git --branch ${BRANCH_NAME:=main}
cd mirra_backend

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix compile
mix release --overwrite

rm -rf /home/mirra_backend
mv /tmp/mirra_backend /home/

mkdir -p /home/.config/systemd/user/
cat <<EOF >/home/.config/systemd/user/game_backend.service
[Unit]
Description=GameBackend
Requires=network-online.target
After=network-online.target

[Service]
WorkingDirectory=/home/mirra_backend
Restart=on-failure
ExecStart=/home/mirra_backend/devops/entrypoint.sh
ExecReload=/bin/kill -HUP
KillSignal=SIGTERM
EnvironmentFile=/home/mirra_backend/.env
LimitNOFILE=4000

[Install]
WantedBy=multi-user.target
EOF

systemctl --user enable game_backend

cat <<EOF >/home/dev/.env
PHX_HOST=${PHX_HOST}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PORT=${PORT}
EOF

systemctl --user stop game_backend

systemctl --user daemon-reload
systemctl --user start game_backend

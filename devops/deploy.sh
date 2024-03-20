#!/usr/bin/env bash
set -ex

if [ -d "/tmp/mirra_backend" ]; then
	rm -rf /tmp/mirra_backend
fi

cd /tmp
git clone https://github.com/lambdaclass/mirra_backend.git --branch ${BRANCH_NAME}
cd mirra_backend

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix compile
mix release --overwrite

rm -rf $HOME/mirra_backend
mv /tmp/mirra_backend $HOME/

mkdir -p $HOME/.config/systemd/user/
cat <<EOF >$HOME/.config/systemd/user/game_backend.service
[Unit]
Description=GameBackend
Requires=network-online.target
After=network-online.target

[Service]
WorkingDirectory=\$HOME/mirra_backend
Restart=on-failure
ExecStart=\$HOME/mirra_backend/devops/entrypoint.sh
ExecReload=/bin/kill -HUP
KillSignal=SIGTERM
EnvironmentFile=\$HOME/mirra_backend/.env
LimitNOFILE=4000

[Install]
WantedBy=multi-user.target
EOF

systemctl --user enable game_backend

cat <<EOF >$HOME/mirra_backend/.env
PHX_HOST=${PHX_HOST}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PORT=${PORT}
EOF

systemctl --user stop game_backend

systemctl --user daemon-reload
systemctl --user start game_backend

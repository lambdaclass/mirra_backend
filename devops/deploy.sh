#!/usr/bin/env bash
. "$HOME/.cargo/env"
set -ex

if [ -d "/tmp/mirra_backend" ]; then
	rm -rf /tmp/mirra_backend
fi

cd /tmp
git clone https://github.com/lambdaclass/mirra_backend.git --branch ${BRANCH_NAME}
cd mirra_backend/

chmod +x devops/entrypoint.sh

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix compile
mix release ${RELEASE} --overwrite
if [ ${RELEASE} == "game_backend" ]; then
	mix ecto.migrate
fi

rm -rf $HOME/mirra_backend
mv /tmp/mirra_backend $HOME/

mkdir -p $HOME/.config/systemd/user/

if [ "$(ls ~/.config/systemd/user/*.service 2>/dev/null | wc -l)" -ge 1 ]; then
    exit 1
fi

cat <<EOF >$HOME/.config/systemd/user/${RELEASE}.service
[Unit]
Description=$RELEASE

[Service]
WorkingDirectory=$HOME/mirra_backend
Restart=on-failure
ExecStart=$HOME/mirra_backend/devops/entrypoint.sh
ExecReload=/bin/kill -HUP
KillSignal=SIGTERM
EnvironmentFile=$HOME/.env
LimitNOFILE=4000

[Install]
WantedBy=multi-user.target
EOF

systemctl --user enable $RELEASE

cat <<EOF >$HOME/.env
PHX_HOST=${PHX_HOST}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PORT=${PORT}
RELEASE=${RELEASE}
EOF

systemctl --user stop $RELEASE

systemctl --user daemon-reload
systemctl --user start $RELEASE

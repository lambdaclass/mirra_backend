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
MIX_ENV=$MIX_ENV mix compile
MIX_ENV=$MIX_ENV mix tailwind configurator --minify
MIX_ENV=$MIX_ENV mix esbuild configurator --minify
MIX_ENV=$MIX_ENV mix phx.digest
mix release ${RELEASE} --overwrite
if [ ${RELEASE} == "central_backend" ]; then
	mix ecto.migrate
fi

rm -rf $HOME/mirra_backend
mv /tmp/mirra_backend $HOME/

mkdir -p $HOME/.config/systemd/user/

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
LimitNOFILE=100000

[Install]
WantedBy=default.target
EOF

systemctl --user enable $RELEASE

cat <<EOF >$HOME/.env
PHX_HOST=${PHX_HOST}
DATABASE_URL=${DATABASE_URL}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
JWT_PRIVATE_KEY_BASE_64=${JWT_PRIVATE_KEY_BASE_64}
PORT=${PORT}
GATEWAY_URL=${GATEWAY_URL}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
BOT_MANAGER_PORT=${BOT_MANAGER_PORT}
BOT_MANAGER_HOST=${BOT_MANAGER_HOST}
RELEASE=${RELEASE}
TARGET_SERVER=${TARGET_SERVER}
LOADTEST_EUROPE_HOST=${LOADTEST_EUROPE_HOST}
LOADTEST_BRAZIL_HOST=${LOADTEST_BRAZIL_HOST}
EOF

systemctl --user stop $RELEASE

systemctl --user daemon-reload
systemctl --user start $RELEASE

#!/usr/bin/env bash
. "$HOME/.cargo/env"
set -ex

if [ -d "/tmp/mirra_backend${_SERVICE_SUFFIX}" ]; then
	rm -rf /tmp/mirra_backend${_SERVICE_SUFFIX}
fi

cd /tmp
git clone https://github.com/lambdaclass/mirra_backend.git --branch ${BRANCH_NAME} mirra_backend${_SERVICE_SUFFIX}
cd mirra_backend${_SERVICE_SUFFIX}

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

rm -rf $HOME/mirra_backend${_SERVICE_SUFFIX}
mv /tmp/mirra_backend${_SERVICE_SUFFIX} $HOME/

mkdir -p $HOME/.config/systemd/user/

cat <<EOF >$HOME/.config/systemd/user/${RELEASE}${_SERVICE_SUFFIX}.service
[Unit]
Description=$RELEASE

[Service]
WorkingDirectory=$HOME/mirra_backend${_SERVICE_SUFFIX}
Restart=on-failure
ExecStart=$HOME/mirra_backend/devops/entrypoint.sh
ExecReload=/bin/kill -HUP
KillSignal=SIGTERM
EnvironmentFile=$HOME/.env${_SERVICE_SUFFIX}
LimitNOFILE=100000

[Install]
WantedBy=default.target
EOF

systemctl --user enable ${RELEASE}${_SERVICE_SUFFIX}

cat <<EOF >$HOME/.env${_SERVICE_SUFFIX}
PHX_HOST=${PHX_HOST}
DATABASE_URL=${DATABASE_URL}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
JWT_PRIVATE_KEY_BASE_64=${JWT_PRIVATE_KEY_BASE_64}
PORT=${PORT}
_SERVICE_SUFFIX=${_SERVICE_SUFFIX}
GATEWAY_URL=${GATEWAY_URL}
OVERRIDE_JWT=${OVERRIDE_JWT}
GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
BOT_MANAGER_PORT=${BOT_MANAGER_PORT}
BOT_MANAGER_HOST=${BOT_MANAGER_HOST}
CONFIGURATOR_HOST=${CONFIGURATOR_HOST}
RELEASE=${RELEASE}
TARGET_SERVER=${TARGET_SERVER}
LOADTEST_EUROPE_HOST=${LOADTEST_EUROPE_HOST}
LOADTEST_BRAZIL_HOST=${LOADTEST_BRAZIL_HOST}
EOF

systemctl --user stop ${RELEASE}${_SERVICE_SUFFIX}

systemctl --user daemon-reload
systemctl --user start ${RELEASE}${_SERVICE_SUFFIX}

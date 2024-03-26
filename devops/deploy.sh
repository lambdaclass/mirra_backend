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

existing_service=$(ls $HOME/.config/systemd/user/*.service 2>/dev/null)

if [[ $(wc -l <<<$existing_service) > 1 || "$(basename ${existing_service})" != "${RELEASE}.service" ]]; then
	echo "The release you are trying to deploy is not the same as the installed"
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
DATABASE_URL=${DATABASE_URL}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PORT=${PORT}
RELEASE=${RELEASE}
EOF

systemctl --user stop $RELEASE

systemctl --user daemon-reload
systemctl --user start $RELEASE

#!/usr/bin/env bash
. "$HOME/.cargo/env"
set -ex

if [ -d "/tmp/mirra_backend" ]; then
	rm -rf /tmp/mirra_backend
fi

cd /tmp
git clone https://github.com/lambdaclass/mirra_backend.git --branch ${BRANCH_NAME}
cd mirra_backend/apps/arena

chmod +x entrypoint.sh

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix assets.deploy
mix compile
mix phx.gen.release
mix release --overwrite

rm -rf $HOME/mirra_backend
mv /tmp/mirra_backend $HOME/

mkdir -p $HOME/.config/systemd/user/
cat <<EOF >$HOME/.config/systemd/user/mirra_backend.service
[Unit]
Description=Game Backend server
Requires=network-online.target
After=network-online.target

[Service]
WorkingDirectory=$HOME/mirra_backend
Restart=on-failure
ExecStart=$HOME/mirra_backend/entrypoint.sh
ExecReload=/bin/kill -HUP
KillSignal=SIGTERM
EnvironmentFile=$HOME/.env
LimitNOFILE=4000

[Install]
WantedBy=multi-user.target
EOF

systemctl --user enable mirra_backend

cat <<EOF >$HOME/.env
PHX_HOST=${PHX_HOST}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
DATABASE_URL=${DATABASE_URL}
EOF

systemctl --user stop mirra_backend

$HOME/mirra_backend/_build/prod/rel/arena/bin/migrate

systemctl --user daemon-reload
systemctl --user start mirra_backend

#!/usr/bin/env bash
set -ex

if [ -d "/tmp/mirra_backend" ]; then
	rm -rf /tmp/mirra_backend
fi

cd /tmp
git clone https://github.com/lambdaclass/mirra_backend.git --branch ${BRANCH_NAME:=main}
cd mirra_backend/apps/arena

chmod +x devops/entrypoint.sh

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix compile
mix phx.gen.release
mix release --overwrite

rsync -avz --delete /tmp/mirra_backend $HOME/

systemctl --user enable arena

cat <<EOF >$HOME/mirra_backend/.env
PHX_HOST=${PHX_HOST}
PHX_SERVER=${PHX_SERVER}
SECRET_KEY_BASE=${SECRET_KEY_BASE}
PORT=${PORT}
EOF

systemctl --user stop arena

systemctl --user daemon-reload
systemctl --user start arena

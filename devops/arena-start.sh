#!/usr/bin/env bash
. "$HOME/.cargo/env"
set -e
set +x  # Disable debug mode
export $(cat $HOME/.env | xargs)
set -x  # Re-enable debug mode

cd mirra_backend/
chmod +x devops/entrypoint.sh
mix local.hex --force && mix local.rebar --force
mix deps.get --only prod
MIX_ENV=prod mix release arena --overwrite

mkdir -p $HOME/.config/systemd/user/

cat <<EOF >$HOME/.config/systemd/user/arena.service
[Unit]
Description=$arena

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

systemctl --user stop arena
systemctl --user daemon-reload
systemctl --user start arena

set +x; echo -e "\nNew Arena server is up and running!\nGo to configurator.championsofmirra.com and add a new Arena Server\nIn URL field, enter: $(hostname).championsofmirra.com"

#!/usr/bin/env bash

: "${SSH_APP_USERNAME:?SSH_APP_USERNAME is not set}"
: "${DATABASE_URL:?DATABASE_URL is not set}"
: "${SECRET_KEY_BASE:?SECRET_KEY_BASE is not set}"
: "${NEWRELIC_KEY:?NEWRELIC_KEY is not set}"
: "${FALOPA:?FALOPA is not set}"

set -ex

export SSH_APP_USERNAME=$SSH_APP_USERNAME
export DATABASE_URL=$DATABASE_URL
export SECRET_KEY_BASE=$SECRET_KEY_BASE
export NEWRELIC_KEY=$NEWRELIC_KEY

cd ~/mirra_backend && make admin-setup-arena-server

sudo rm -rf /home/$SSH_APP_USERNAME/mirra_backend
sudo mv ~/mirra_backend /home/$SSH_APP_USERNAME/
sudo chown -R $SSH_APP_USERNAME:$SSH_APP_USERNAME /home/$SSH_APP_USERNAME/mirra_backend

sudo mv ~/.ssh/id_ed25519 /home/$SSH_APP_USERNAME/.ssh/
sudo chown $SSH_APP_USERNAME:$SSH_APP_USERNAME /home/$SSH_APP_USERNAME/.ssh/id_ed25519

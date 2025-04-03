#!/usr/bin/env bash

set -ex

echo $SSH_APP_USERNAME
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

#!/usr/bin/env bash
. "${HOME}/.cargo/env"
set -ex

export PATH=${PATH}:/opt/homebrew/bin/

if [ -d "/tmp/mirra_backend" ]; then
	rm -rf /tmp/mirra_backend
fi

cd /tmp
git clone git@github.com:lambdaclass/mirra_backend.git --branch ${BRANCH_NAME} mirra_backend
cd mirra_backend

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

/Users/lambdaclass/arena/mirra_backend/_build/prod/rel/arena/bin/arena stop

rm -rf ${HOME}/arena/mirra_backend
mv /tmp/mirra_backend ${HOME}/arena/

/Users/lambdaclass/arena/mirra_backend/_build/prod/rel/arena/bin/arena daemon

# If no BRANCH_NAME is provided, defaults to main

BRANCH_NAME="$1"
BRANCH_NAME=${BRANCH_NAME:-"main"}

export MIX_ENV=prod
cd /tmp
git clone https://github.com/lambdaclass/curse_of_myrra.git curse_of_myrra
cd curse_of_myrra/
git checkout $BRANCH_NAME
cd server/load_test

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix assets.deploy
mix compile
mix phx.gen.release
mix release --overwrite

rm -rf /root/curse_of_myrra
mv /tmp/curse_of_myrra /root/

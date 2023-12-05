set -xe

# RUN FROM /root

# Set locales
export LC_CTYPE="en_US.UTF-8"
echo 'LC_CTYPE="en_US.UTF-8"' >> /etc/default/locale

# Add the Debian security repository source
echo "deb http://security.debian.org/debian-security buster/updates main" > /etc/apt/sources.list.d/security.list
apt-get update -y

# Install tools and dependencies
apt update -y
apt install -y curl \
               git \
               vim \
               telnet \
               build-essential \
               libncurses5-dev \
               libncurses5 \
               libssh-dev \
               autoconf \
               automake \
               zip \
               unzip \
               gnupg2 \
               wget \
               inotify-tools \
               certbot \
               ufw \
               libyaml-0-2 \
               python3 \
               tar \
               openssl \
               libssl-dev \
               libsctp1 \
               libssl1.1

# Install rust
wget https://static.rust-lang.org/dist/rust-1.74.0-x86_64-unknown-linux-gnu.tar.gz
tar -xvf rust-1.74.0-x86_64-unknown-linux-gnu.tar.gz
cd rust-1.74.0-x86_64-unknown-linux-gnu
./install.sh
cd ..
rm -rf rust-1.74.0-x86_64-unknown-linux-gnu && rust-1.74.0-x86_64-unknown-linux-gnu.tar.gz

cd 

# Install erlang
wget -P ~/ https://binaries2.erlang-solutions.com/debian/pool/contrib/e/esl-erlang/esl-erlang_26.0.2-1~debian~bullseye_amd64.deb 
sudo dpkg -i ~/esl-erlang_26.0.2-1~debian~bullseye_amd64.deb

# Install elixir
wget -P ~/ https://github.com/elixir-lang/elixir/releases/download/v1.15.4/elixir-otp-26.zip
sudo unzip -o ~/elixir-otp-26.zip -d /usr/local/

# Install nodejs
wget -P ~/ https://nodejs.org/dist/v20.5.1/node-v20.5.1-linux-x64.tar.xz
sudo tar -xf ~/node-v20.5.1-linux-x64.tar.xz --directory=/usr/local/ --strip-components=1

# Remove binaries
rm ~/node-v20.5.1-linux-x64.tar.xz ~/elixir-otp-26.zip ~/esl-erlang_26.0.2-1~debian~bullseye_amd64.deb

# Install postgres
sudo echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
# -> this last command prompted an error
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update -y
sudo apt install -y postgresql-15

# You'll also need to setup the db with `mix ecto.setup && mix ecto.migrate`

# Install newrelic agent

BRANCH_NAME="$1"
BRANCH_NAME=${BRANCH_NAME:-"main"}

export MIX_ENV=prod

if [ -d "/tmp/game_backend" ]; then
  rm -rf /tmp/game_backend
fi

# Clone and compile the game.
cd /tmp
git clone git@github.com:lambdaclass/game_backend.git --branch ${BRANCH_NAME}
cd game_backend/

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
mix deps.compile
mix assets.deploy
mix compile
mix phx.gen.release
mix release --overwrite

rm -rf $HOME/game_backend
mv /tmp/game_backend $HOME/game_backend

$HOME/game_backend/_build/prod/rel/dark_worlds_server/bin/migrate

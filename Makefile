.PHONY: deps db run start format docs credo check generate-protos generate-arena-protos generate-game-client-protos

deps:
	cd apps/game_client/assets && npm install
	mix deps.get

db: deps
	mix ecto.reset

run:
	iex -S mix phx.server

start: db run

purge:
	rm -rf devenv.lock .devenv .devenv.flake.nix _build/
	devenv gc

format:
	mix format

credo:
	mix credo

check: credo format

docs:
	mix docs

generate-protos: generate-gateway-protos generate-arena-protos generate-game-client-protos generate-arena-load-test-protos generate-bot-manager-protos format

generate-gateway-protos:
	protoc \
		--elixir_out=apps/gateway/lib/gateway/serialization \
		--elixir_opt=package_prefix=gateway.serialization \
		--proto_path=apps/serialization \
		gateway.proto

generate-arena-protos:
	protoc \
		--elixir_out=apps/arena/lib/arena/serialization \
		--elixir_opt=package_prefix=arena.serialization \
		--proto_path=apps/serialization \
		messages.proto

generate-game-client-protos:
	protoc \
		--elixir_out=apps/game_client/lib/game_client/protobuf \
		--elixir_opt=package_prefix=game_client.protobuf \
		--proto_path=apps/serialization \
		messages.proto

	protoc \
		--js_out=import_style=commonjs:apps/game_client/assets/js/protobuf \
		--proto_path=apps/serialization \
		messages.proto

generate-arena-load-test-protos:
	protoc \
		--elixir_out=apps/arena_load_test/lib/arena_load_test/serialization \
		--elixir_opt=package_prefix=arena_load_test.serialization \
		--proto_path=apps/serialization \
		messages.proto

generate-bot-manager-protos:
	protoc \
		--elixir_out=apps/bot_manager/lib/protobuf \
		--elixir_opt=package_prefix=bot_manager.protobuf \
		--proto_path=apps/serialization \
		messages.proto

# INFRA
## Check server specs (loadtests)
server-specs:
	./devops/server_specs.sh

## New server. Setup dependencies.
## Run these as admin user

admin-setup-arena-server: debian-install-deps setup-caddy create-env-file setup-aws-dns

debian-install-deps:
	sudo apt update -y
	sudo apt install -y rsync libssl-dev libncurses5 libsctp1 wget systemd-timesyncd ufw
	wget -P /tmp/ http://ftp.de.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1w-0+deb11u1_amd64.deb
	sudo dpkg -i /tmp/libssl1.1_1.1.1w-0+deb11u1_amd64.deb
	rm /tmp/libssl1.1_1.1.1w-0+deb11u1_amd64.deb
	wget -P /tmp/ https://binaries2.erlang-solutions.com/debian/pool/contrib/e/esl-erlang/esl-erlang_26.2.3-1~debian~buster_amd64.deb
	sudo dpkg -i /tmp/esl-erlang_26.2.3-1~debian~buster_amd64.deb
	rm /tmp/esl-erlang_26.2.3-1~debian~buster_amd64.deb
	wget -P /tmp/ https://github.com/elixir-lang/elixir/releases/download/v1.16.3/elixir-otp-26.zip
	sudo unzip -d /usr/ /tmp/elixir-otp-26.zip
	rm /tmp/elixir-otp-26.zip

setup-caddy:
	sudo ufw allow 80
	sudo ufw allow 443
	sudo sed -i "1i $$(hostname).championsofmirra.com {" /etc/caddy/Caddyfile; \
	sudo sed -i "2i \	reverse_proxy localhost:4000" /etc/caddy/Caddyfile; \
	sudo sed -i "3i }" /etc/caddy/Caddyfile;
	sudo systemctl restart caddy

create-env-file:
	@truncate -s0 /home/app/.env
	@echo "PHX_HOST=$$(hostname).championsofmirra.com" >> /home/app/.env
	@echo "DATABASE_URL=ecto://postgres:postgres@localhost:5432/game_backend" >> /home/app/.env
	@echo "CONFIGURATOR_DATABASE_URL=" >> /home/app/.env
	@echo "PHX_SERVER=true" >> /home/app/.env
	@echo "SECRET_KEY_BASE=ecoRrjLPSLqYamG2+CCuTF24ZRkSApTYC1DBBIaq2PgPap1LFRZ4oKlcOkuYA+Ew" >> /home/app/.env
	@echo "JWT_PRIVATE_KEY_BASE_64=" >> /home/app/.env
	@echo "PORT=4000" >> /home/app/.env
	@echo "RELEASE_NODE=" >> /home/app/.env
	@echo "_SERVICE_SUFFIX=" >> /home/app/.env
	@echo "GATEWAY_URL=https://$$(hostname).championsofmirra.com" >> /home/app/.env
	@echo "METRICS_ENDPOINT_PORT=" >> /home/app/.env
	@echo "OVERRIDE_JWT=" >> /home/app/.env
	@echo "GOOGLE_CLIENT_ID=" >> /home/app/.env
	@echo "BOT_MANAGER_PORT=4003" >> /home/app/.env
	@echo "BOT_MANAGER_HOST=bot-manager.championsofmirra.com" >> /home/app/.env
	@echo "CONFIGURATOR_HOST=" >> /home/app/.env
	@echo "CONFIGURATOR_GOOGLE_CLIENT_ID=" >> /home/app/.env
	@echo "CONFIGURATOR_GOOGLE_CLIENT_SECRET=" >> /home/app/.env
	@echo "RELEASE=arena" >> /home/app/.env
	@echo "TARGET_SERVER=" >> /home/app/.env
	@echo "LOADTEST_EUROPE_HOST=" >> /home/app/.env
	@echo "LOADTEST_BRAZIL_HOST=" >> /home/app/.env
	@echo "LOADTEST_CHILE_HOST=" >> /home/app/.env
	@echo "NEWRELIC_APP_NAME=testing-europe" >> /home/app/.env
	@echo "NEWRELIC_KEY=8ae39e7ac1a8aa938b65f21daed82bbdFFFFNRAL" >> /home/app/.env

setup-aws-dns:
	aws route53 change-resource-record-sets \
    --hosted-zone-id "Z10155211PTW2X4H9NGDM" \
    --change-batch "{\"Changes\":[{\"Action\":\"CREATE\",\"ResourceRecordSet\":{\"Name\":\"$$(hostname).championsofmirra.com\",\"Type\":\"A\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"$$(curl -s ipinfo.io/ip)\"}]}}]}"

## Run this as app or dev user

app-setup-arena-server: debian-install-dev-deps

debian-install-dev-deps:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

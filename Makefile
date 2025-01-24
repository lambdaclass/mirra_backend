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

## INFRA
## Run these as admin
debian-install-deps:
	sudo apt update -y
	sudo apt install -y rsync libssl-dev libncurses5 libsctp1 wget systemd-timesyncd
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
	@read -p "Enter the server dns (e.g: 'arena-testing.championsofmirra.com'): " user_input; \
	sudo sed -i "1i $$user_input {" /etc/caddy/Caddyfile; \
	sudo sed -i "2i \	reverse_proxy localhost:4000" /etc/caddy/Caddyfile; \
	sudo sed -i "3i }" /etc/caddy/Caddyfile;
	sudo systemctl restart caddy

## Run this as dev
debian-install-dev-deps:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

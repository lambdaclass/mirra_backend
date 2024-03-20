.PHONY: deps db run start format credo check generate-protos generate-arena-protos generate-game-client-protos

deps:
	cd apps/game_client/assets && npm install
	mix deps.get

db: deps
	mix ecto.reset

run:
	devops/deploy.sh

start: db run

purge:
	rm -rf devenv.lock .devenv .devenv.flake.nix _build/
	devenv gc

format:
	mix format

credo:
	mix credo

check: credo format

generate-protos: generate-gateway-protos generate-arena-protos generate-game-client-protos generate-arena-load-test-protos format

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

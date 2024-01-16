.PHONY: start format generate-protos generate-arena-protos generate-game-client-protos

start:
	cd apps/arena && docker-compose up -d
	cd apps/game_client && docker-compose up -d
	cd apps/game_client/assets && npm install
	mix deps.get
	iex -S mix phx.server

format:
	mix format

generate-protos: generate-arena-protos generate-game-client-protos

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

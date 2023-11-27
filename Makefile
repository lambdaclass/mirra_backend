.PHONY: format check

format:
	mix format
	cargo fmt --manifest-path native/game_backend/Cargo.toml
	cd load_test && mix format

check:
	mix credo --strict
	cargo clippy --manifest-path native/game_backend/Cargo.toml -- -D warnings

.PHONY: setup dependencies db stop start run tests elixir-tests shell prepush credo

setup: dependencies
	mix deps.compile
	mix setup

dependencies:
	mix deps.get

db:
	docker compose up -d

stop:
	docker compose down

start: db dependencies run

run:
	mix assets.build
	iex -S mix phx.server

tests: elixir-tests

elixir-tests:
	mix test

shell:
	iex -S mix run --no-start --no-halt

prepush: format credo tests

credo:
	mix credo --strict

gen-protobuf: gen-server-protobuf gen-load-test-protobuf
	
gen-server-protobuf:
	protoc \
		--elixir_out=transform_module=DarkWorldsServer.Communication.ProtoTransform:./lib/dark_worlds_server/communication/ \
		--elixir_opt=package_prefix=dark_worlds_server.communication.proto \
		messages.proto

# Elixir's protobuf lib does not add a new line nor formats the output file
# so we do it here with a format:
	mix format "./lib/dark_worlds_server/communication/*"

gen-load-test-protobuf:
	protoc \
		--elixir_out=./load_test/lib/load_test/communication \
		--elixir_opt=package_prefix=load_test.communication.proto \
		messages.proto

# Elixir's protobuf lib does not add a new line nor formats the output file
# so we do it here with a format:
	mix format "./load_test/lib/load_test/communication/*"

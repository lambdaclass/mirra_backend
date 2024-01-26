.PHONY: run deps start stop generate-protos format lints check

run:
	iex -S mix phx.server

deps:
	mix deps.get

start:
	iex -S mix phx.server

stop:
	docker compose down

generate-protos:
	protoc \
		--elixir_out=lib/arena/serialization \
		--elixir_opt=package_prefix=arena.serialization \
		--proto_path=../serialization \
		messages.proto

format:
	mix format
	cd native/physics && cargo fmt --all

lints:
	mix credo
	cd native/physics && cargo clippy --all-targets -- -D warnings

check: format lints
	mix test

.PHONY: run deps start stop generate-ex-protos generate-protos format lints check

run:
	iex -S mix phx.server

deps:
	mix deps.get

start:
	docker-compose up -d
	iex -S mix phx.server

stop:
	docker-compose down

generate-ex-protos:
	protoc \
		--elixir_out=lib/arena \
		--elixir_opt=package_prefix=arena.serialization \
		serialization/messages.proto

generate-protos: generate-ex-protos

format:
	mix format
	cd native/physics && cargo fmt --all

lints:
	mix credo
	cd native/physics && cargo clippy --all-targets -- -D warnings

check: format lints
	mix test

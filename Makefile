.PHONY: deps db down generate-ex-protos format lints check

deps:
	mix deps.get

db:
	docker-compose up -d

down:
	docker-compose down

generate-ex-protos:
	protoc \
		--elixir_out=lib/game_backend/protobuf \
		--elixir_opt=package_prefix=game_backend.protobuf \
		messages.proto

format:
	mix format --check-formatted
	cd native/physics && cargo fmt --all

lints:
	mix credo
	cd native/physics && cargo clippy --all-targets -- -D warnings

check: format lints
	mix test

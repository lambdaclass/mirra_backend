run:
	iex -S mix phx.server

deps:
	mix deps.get
	cd assets && npm install

start:
	docker-compose up -d
	iex -S mix phx.server

generate-ex-protos:
	protoc \
		--elixir_out=lib/lambda_game_backend/protobuf \
		--elixir_opt=package_prefix=lambda_game_backend.protobuf \
		messages.proto

generate-js-protos:
	protoc messages.proto --js_out=import_style=commonjs:assets/js/protobuf

generate-protos: generate-ex-protos generate-js-protos

check: format
	mix credo --strict
	mix test

format:
	mix format --check-formatted
	cd native/state_manager_backend && cargo fmt --all

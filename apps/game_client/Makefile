.PHONY: run deps start stop generate-ex-protos generate-js-protos generate-protos format lints check

run:
	iex -S mix phx.server

deps:
	mix deps.get
	cd assets && npm install

start:
	docker compose up -d
	iex -S mix phx.server

stop:
	docker compose down

generate-ex-protos:
	protoc \
		--elixir_out=lib/game_client/protobuf \
		--elixir_opt=package_prefix=game_client.protobuf \
		messages.proto

generate-js-protos:
	protoc messages.proto --js_out=import_style=commonjs:assets/js/protobuf

generate-protos: generate-ex-protos generate-js-protos

format:
	mix format

lints:
	mix credo

check: format lints
	mix test

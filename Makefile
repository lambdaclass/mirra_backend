.PHONY: deps run start stop generate-ex-protos generate-js-protos generate-protos check

run:
	iex -S mix phx.server

deps:
	mix deps.get
	cd assets && npm install

start:
	docker-compose up -d
	iex -S mix phx.server

stop:
	docker-compose down

generate-ex-protos:
	protoc \
		--elixir_out=lib/lambda_game_backend/protobuf \
		--elixir_opt=package_prefix=lambda_game_backend.protobuf \
		messages.proto

generate-js-protos:
	protoc messages.proto --js_out=import_style=commonjs:assets/js/protobuf

generate-protos: generate-ex-protos generate-js-protos

check: 
	mix format --check-formatted
	mix credo --strict
	mix test

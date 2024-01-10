.PHONY: deps run start stop generate-ex-protos generate-js-protos generate-protos format lints check

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
		--elixir_out=lib/web/protobuf \
		--elixir_opt=package_prefix=web.protobuf \
		messages.proto

generate-js-protos:
	protoc messages.proto --js_out=import_style=commonjs:assets/js/protobuf

generate-protos: generate-ex-protos generate-js-protos

format:
	mix format --check-formatted
	cd native/physics && cargo fmt --all

lints:
	mix credo
	cd native/physics && cargo clippy --all-targets -- -D warnings

check: format lints
	mix test

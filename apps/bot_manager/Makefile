.PHONY: run deps start stop generate-protos format lints check

run:
	iex -S mix phx.server

deps:
	mix deps.get

start:
	iex -S mix phx.server

stop:
	docker compose down

format:
	mix format
	cd native/astar && cargo fmt --all

lints:
	mix credo
	cd native/astar && cargo clippy --all-targets -- -D warnings

check: format lints
	mix test

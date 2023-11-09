PHONY: format check

format:
	mix format
	cargo fmt --manifest-path native/lambda_backend_game_engine/Cargo.toml

check:
	mix credo --strict
	cargo clippy --manifest-path native/lambda_backend_game_engine/Cargo.toml -- -D warnings

.PHONY: start

start:
	cd apps/game_client/assets && npm install
	mix deps.get
	iex -S mix phx.server

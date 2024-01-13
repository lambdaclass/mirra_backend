.PHONY: start

start:
	mix deps.get
	iex -S mix phx.server

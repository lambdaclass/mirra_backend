defmodule LambdaGameBackend.WsClient do
  @moduledoc """
  false
  """
  use WebSockex

  def start_link(_url, state) do
    WebSockex.start_link("http://localhost:4000/play/1", __MODULE__, state)
  end

  def handle_frame({type, msg}, state) do
    IO.puts("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    {:ok, state}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{inspect(msg)}")
    {:reply, frame, state}
  end

  def send_command(pid, _command) do
    direction = %LambdaGameBackend.Protobuf.Direction{x: 1.0, y: 0.0}
    direction_encoded = LambdaGameBackend.Protobuf.Direction.encode(direction)

    WebSockex.cast(pid, {:send, {:binary, direction_encoded}})
  end
end

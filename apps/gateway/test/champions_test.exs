defmodule Gateway.Test.Champions do
  @moduledoc """
  Test for Champions of Mirra messages.
  """
  use ExUnit.Case

  alias Gateway.Serialization.{User, Error, WebSocketResponse}
  alias Gateway.SocketTester

  # import Plug.Conn
  # import Phoenix.ConnTest

  setup_all do
    # Start Phoenix endpoint
    {:ok, _} =
      Plug.Cowboy.http(Gateway.Endpoint, [],
        ip: {127, 0, 0, 1},
        port: 4001,
        dispatch: [
          _: [{"/2", Gateway.ChampionsSocketHandler, []}]
        ]
      )

    {:ok, socket_tester} = SocketTester.start_link()

    {:ok, %{socket_tester: socket_tester}}
  end

  test "users", %{socket_tester: socket_tester} do
    # Create our user
    :ok = SocketTester.create_user(socket_tester, "Username")
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:user, %User{}}}

    fetch_last_message(socket_tester)
    %WebSocketResponse{response_type: {:user, user}} = get_last_message()

    # Creating another user with the same name fails
    :ok = SocketTester.create_user(socket_tester, "Username")
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:error, %Error{reason: "username_taken"}}}

    # Get user by name
    :ok = SocketTester.get_user_by_username(socket_tester, "Username")
    fetch_last_message(socket_tester)
    assert_receive %WebSocketResponse{response_type: {:user, ^user}}
  end

  defp get_last_message() do
    receive do
      message ->
        message
    after
      5000 ->
        raise "No message"
    end
  end

  defp fetch_last_message(socket_tester) do
    :timer.sleep(50)
    send(socket_tester, {:last_message, self()})
  end
end

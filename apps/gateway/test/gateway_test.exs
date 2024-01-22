defmodule GatewayTest do
  use ExUnit.Case
  doctest Gateway

  test "greets the world" do
    assert Gateway.hello() == :world
  end
end

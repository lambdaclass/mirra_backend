defmodule UsersTest do
  use ExUnit.Case
  doctest Users

  test "greets the world" do
    assert Users.hello() == :world
  end
end

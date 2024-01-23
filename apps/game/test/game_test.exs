defmodule GameTest do
  use ExUnit.Case
  doctest Game

  test "greets the world" do
    assert Game.hello() == :world
  end
end

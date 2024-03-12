defmodule BotManagerTest do
  use ExUnit.Case
  doctest BotManager

  test "greets the world" do
    assert BotManager.hello() == :world
  end
end

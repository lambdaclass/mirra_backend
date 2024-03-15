defmodule BotSupervisorTest do
  use ExUnit.Case
  doctest BotSupervisor

  test "greets the world" do
    assert BotSupervisor.hello() == :world
  end
end

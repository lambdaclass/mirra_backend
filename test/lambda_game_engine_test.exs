defmodule LambdaGameEngineTest do
  use ExUnit.Case
  doctest LambdaGameEngine

  test "greets the world" do
    assert LambdaGameEngine.hello() == :world
  end
end

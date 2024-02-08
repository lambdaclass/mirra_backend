defmodule ChampionsOfMirraTest do
  use ExUnit.Case
  doctest Champions

  test "greets the world" do
    assert Champions.hello() == :world
  end
end

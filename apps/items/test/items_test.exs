defmodule ItemsTest do
  use ExUnit.Case
  doctest Items

  test "greets the world" do
    assert Items.hello() == :world
  end
end

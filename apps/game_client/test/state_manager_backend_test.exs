defmodule PhysicsTest do
  use ExUnit.Case
  doctest Physics

  test "sum" do
    assert Physics.add(1, 2) == 3
  end
end

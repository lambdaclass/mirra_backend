defmodule GameBackendTest do
  use ExUnit.Case
  doctest GameBackend

  test "greets the world" do
    assert GameBackend.hello() == :world
  end
end

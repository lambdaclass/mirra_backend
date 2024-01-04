defmodule StateManagerBackendTest do
  use ExUnit.Case
  doctest StateManagerBackend

  test "sum" do
    assert StateManagerBackend.add(1, 2) == 3
  end
end

defmodule Arena.Utils do
  @moduledoc """
  Utils module.
  It contains utility functions like math functions.
  """

  def normalize(x, y) when x == 0 and y == 0 do
    %{x: x, y: y}
  end

  def normalize(x, y) do
    length = :math.sqrt(x * x + y * y)
    %{x: x / length, y: y / length}
  end
end

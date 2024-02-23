defmodule Arena.Utils do
  @moduledoc """
  Utils module.
  It contains utility functions like math functions.
  """

  def normalize(%{x: 0, y: 0}) do
    %{x: 0, y: 0}
  end

  def normalize(%{x: x, y: y}) do
    length = :math.sqrt(x * x + y * y)
    %{x: x / length, y: y / length}
  end
end

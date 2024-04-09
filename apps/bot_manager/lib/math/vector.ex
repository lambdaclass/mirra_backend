defmodule BotManager.Math.Vector do
  @moduledoc """
  Module to handle math operations with vectors
  """

  def sub(vector, value) when is_integer(value) or is_float(value) do
    %{
      x: vector.x - value,
      y: vector.y - value
    }
  end

  def sub(first_vector, second_vector) do
    %{
      x: first_vector.x - second_vector.x,
      y: first_vector.y - second_vector.y
    }
  end

  def mult(vector, value) when is_integer(value) or is_float(value) do
    %{
      x: vector.x * value,
      y: vector.y * value
    }
  end

  def mult(first_vector, second_vector) do
    %{
      x: first_vector.x * second_vector.x,
      y: first_vector.y * second_vector.y
    }
  end
end

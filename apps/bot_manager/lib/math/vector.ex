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

  # Using the rotation matrix
  def rotate_by_degrees(%{x: x, y: y}, angle_in_degrees) do
    angle_in_radians = Math.deg2rad(angle_in_degrees)
    x = x * Math.cos(angle_in_radians) - y * Math.sin(angle_in_radians)
    y = x * Math.sin(angle_in_radians) + y * Math.cos(angle_in_radians)

    %{
      x: x,
      y: y
    }
  end
end

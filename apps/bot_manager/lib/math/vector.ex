defmodule BotManager.Math.Vector do
  @moduledoc """
  Module to handle math operations with vectors
  """

  def sub(vector, value) when is_integer(value) or is_float(value) do
    Map.new(vector, fn {_key, vector_value} ->
      vector_value - value
    end)
  end

  def sub(first_vector, second_vector) do
    Map.merge(first_vector, second_vector, fn _key, first_vector_value, second_vector_value ->
      first_vector_value - second_vector_value
    end)
  end

  def mult(vector, value) when is_integer(value) or is_float(value) do
    Map.new(vector, fn {key, vector_value} ->
      {key, vector_value * value}
    end)
  end

  def mult(first_vector, second_vector) do
    Map.merge(first_vector, second_vector, fn _key, first_vector_value, second_vector_value ->
      first_vector_value * second_vector_value
    end)
  end
end

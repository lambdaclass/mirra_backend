defmodule Configurator.Ecto.JsonBlob do
  use Ecto.Type

  def type, do: :map

  def cast(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, _map} -> {:ok, value}
      _ -> {:error, message: "is invalid JSON"}
    end
  end

  def cast(_), do: :error

  def dump(value) when is_binary(value) do
    case Jason.decode(value) do
      {:ok, map} -> {:ok, map}
      _ -> :error
    end
  end

  def dump(_), do: :error

  def load(value) when is_map(value) do
    case Jason.encode(value) do
      {:ok, json_data} -> {:ok, json_data}
      _ -> :error
    end
  end

  def load(_), do: :error
end

defmodule ConfiguratorWeb.UtilsConfiguration do
  @moduledoc """
  Module with utility functions for configuration data.
  """
  def nested_maps_level(map, level) do
    map
    |> Enum.reduce(level, fn {_key, value}, level ->
      if is_map(value) do
        nested_maps_level(value, level + 1)
      else
        level
      end
    end)
  end

  def key_prettier(key) do
    key
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end

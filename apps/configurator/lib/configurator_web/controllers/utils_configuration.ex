defmodule ConfiguratorWeb.UtilsConfiguration do
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
end

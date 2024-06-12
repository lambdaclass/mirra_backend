defmodule ConfiguratorWeb.UtilsConfiguration do
  @moduledoc """
  Module with utility functions for configuration data.
  """
  def key_prettier(key) do
    key
    |> String.split("_")
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end

defmodule ConfiguratorWeb.Utils do
  @moduledoc """
  Utility functions for the Configurator App
  """

  def transform_to_map_from_ecto_struct(ecto_struct) when is_struct(ecto_struct) do
    ecto_struct
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:__struct__)
    |> Map.delete(:inserted_at)
    |> Map.delete(:updated_at)
    |> Map.delete(:id)
  end

  def transform_to_map_from_ecto_struct(ecto_structs) when is_list(ecto_structs) do
    Enum.map(ecto_structs, fn ecto_struct ->
      transform_to_map_from_ecto_struct(ecto_struct)
    end)
  end
end

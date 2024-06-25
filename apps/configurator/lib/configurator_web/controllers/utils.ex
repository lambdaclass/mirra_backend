defmodule ConfiguratorWeb.Utils do
  @moduledoc """
  Utility functions for the Configurator App
  """

  def transform_to_map_from_ecto_struct(ecto_struct) when is_struct(ecto_struct) do
    ecto_struct
    |> Map.from_struct()
    |> Map.drop([
      :__meta__,
      :__struct__,
      :inserted_at,
      :updated_at,
      :id
    ])
  end

  def transform_to_map_from_ecto_struct(ecto_structs) when is_list(ecto_structs) do
    Enum.map(ecto_structs, fn ecto_struct ->
      transform_to_map_from_ecto_struct(ecto_struct)
    end)
  end
end

defmodule Configurator.Utils do
  @moduledoc """
  Helper module
  """

  def list_curse_skills_by_version_grouped_by_type(version_id) do
    GameBackend.Units.Skills.list_curse_skills_by_version(version_id)
    |> Enum.group_by(& &1.type)
  end

  def parse_json_params(map_configuration_params) do
    map_configuration_params
    |> Map.update("initial_positions", "", &parse_json/1)
    |> Map.update("obstacles", "", &parse_json/1)
    |> Map.update("bushes", "", &parse_json/1)
    |> Map.update("pools", "", &parse_json/1)
    |> Map.update("crates", "", &parse_json/1)
    |> Map.update("square_wall", "", &parse_json/1)
  end

  defp parse_json(""), do: []
  defp parse_json(nil), do: []

  defp parse_json(json_param) do
    case Jason.decode(json_param) do
      {:ok, json} -> json
      {:error, _} -> json_param
    end
  end

  def embed_to_string(embeds) when is_list(embeds) do
    embeds
    |> Enum.map(&embed_to_string/1)
    |> Enum.reject(&(&1 == nil))
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
  end

  def embed_to_string([]), do: ""
  def embed_to_string(nil), do: nil
  def embed_to_string(string) when is_binary(string), do: string

  def embed_to_string(%Ecto.Changeset{action: :replace}) do
    nil
  end

  def embed_to_string(%Ecto.Changeset{} = changeset) do
    changeset.params |> Map.delete("id")
  end

  def embed_to_string(struct) when is_map(struct) do
    struct
  end
end

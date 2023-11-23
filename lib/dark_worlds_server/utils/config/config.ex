defmodule Utils.Config do
  @streaming_assets_path "../client/Assets/StreamingAssets/"

  @spec read_config(atom) :: map | {:error, term}
  def read_config(type) do
    with path <- get_config_type_filepath(type),
         {:ok, body} <- File.read(path),
         body <- remove_bom(body),
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      json
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_config_type_filepath(:characters), do: Path.absname(@streaming_assets_path <> "Characters.json")
  defp get_config_type_filepath(:game_settings), do: Path.absname(@streaming_assets_path <> "GameSettings.json")
  defp get_config_type_filepath(:skills), do: Path.absname(@streaming_assets_path <> "Skills.json")

  defp remove_bom(str), do: String.replace_prefix(str, "\uFEFF", "")
end

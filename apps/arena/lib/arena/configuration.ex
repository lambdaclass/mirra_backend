defmodule Arena.Configuration do
  def get_game_config() do
    {:ok, config_json} =
      Application.app_dir(:arena, "priv/config.json")
      |> File.read()

    Jason.decode!(config_json, [{:keys, :atoms}])
  end
end

defmodule GameBackend.CurseOfMirra.Config do
  @moduledoc """
    Module to import config to the db related to Curse Of Mirra from json files
  """

  alias GameBackend.CurseOfMirra.Quests

  def import_quest_descriptions_config() do
    {:ok, skills_json} =
      Application.app_dir(:game_backend, "priv/curse_of_mirra/quests_descriptions.json")
      |> File.read()

    Jason.decode!(skills_json, [{:keys, :atoms}])
    |> Quests.upsert_quests()
  end

  def get_characters_config() do
    {:ok, characters_config_json} =
      Application.app_dir(:game_backend, "priv/characters_config.json")
      |> File.read()

    Jason.decode!(characters_config_json, [{:keys, :atoms}])
    |> Map.get(:characters)
  end

  def get_items_templates_config() do
    {:ok, items_config_json} =
      Application.app_dir(:game_backend, "priv/items_templates.json")
      |> File.read()

    Jason.decode!(items_config_json, [{:keys, :atoms}])
    |> Map.get(:items)
  end
end

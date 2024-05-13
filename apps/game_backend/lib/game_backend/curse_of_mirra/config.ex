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
end

defmodule GameBackend.CurseOfMirra.Config do
  @moduledoc """
    Module to import config to the db related to Curse Of Mirra from json files
  """

  alias GameBackend.CurseOfMirra.Quests
  alias GameBackend.Utils
  alias GameBackend.Stores.Store
  alias GameBackend.Repo
  alias GameBackend.Users.Currencies.Currency

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

  def import_stores_config() do
    {:ok, stores_config_json} =
      Application.app_dir(:game_backend, "priv/stores_config.json")
      |> File.read()

    Jason.decode!(stores_config_json, [{:keys, :atoms}])
    |> Enum.map(fn {store_name, store_info} ->
      Map.put(store_info, :name, Atom.to_string(store_name))
      |> Map.put(:start_date, datetime_from_string(store_info.start_date))
      |> Map.put(:end_date, datetime_from_string(store_info.end_date))
      |> Map.put(
        :items,
        Enum.map(store_info.items, fn item_template ->
          purchase_costs =
            Enum.map(item_template.purchase_costs, fn purchase_cost ->
              Map.put(
                purchase_cost,
                :currency_id,
                Repo.get_by!(Currency, name: purchase_cost.currency, game_id: Utils.get_game_id(:curse_of_mirra))
                |> Map.get(:id)
              )
            end)

          Map.put(item_template, :game_id, Utils.get_game_id(:curse_of_mirra))
          |> Map.put(:rarity, 0)
          |> Map.put(:config_id, item_template.name)
          |> Map.put(:purchase_costs, purchase_costs)
        end)
      )
    end)
    |> Enum.each(fn store ->
      Store.changeset(%Store{}, store)
      |> Repo.insert!()
    end)
  end

  ################## Helpers ##################
  defp datetime_from_string(nil), do: nil

  defp datetime_from_string(string_date) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(string_date)
    datetime
  end

  #############################################
end

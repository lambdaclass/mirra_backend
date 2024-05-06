defmodule GameBackend.Currencies do
  @moduledoc """
  Module to handle currencies transactions with gamebackend
  """
  def process_match_end_currency_rewards(state) do
    {:ok, conrrency_config_json} =
      Application.app_dir(:arena, "priv/currencies_rules.json")
      |> File.read()

    currency_config = Jason.decode!(conrrency_config_json, [{:keys, :atoms}])


  end
end

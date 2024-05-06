defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Matches.ArenaMatchResult

  def create_arena_match_results(results) do
    {:ok, conrrency_config_json} =
      Application.app_dir(:game_backend, "priv/currencies_rules.json")
      |> File.read()

    currency_config =
      Jason.decode!(conrrency_config_json)

    transaction =
      Enum.reduce(results, Multi.new(), fn result, transaction_acc ->
        changeset = ArenaMatchResult.changeset(%ArenaMatchResult{}, result)

        amount_of_trophies = Currencies.get_amount_of_currency_by_name(result["user_id"], "Trophies")

        {:ok, google_user} = Users.get_google_user(result["user_id"])

        amount =
          get_amount_of_trophies_to_modify(amount_of_trophies, result["position"], currency_config)

        Multi.insert(transaction_acc, {:insert, result["user_id"]}, changeset)
        |> Multi.run(
          {:add_trophies_to, result["user_id"]},
          fn _, _ ->
            Currencies.add_currency_by_name!(google_user.user.id, "Trophies", amount)
          end
        )
      end)

    Repo.transaction(transaction)
  end

  def get_amount_of_trophies_to_modify(current_trophies, position, currencies_config) do
    Enum.sort_by(currencies_config["rank"], fn %{"maximum_rank" => maximum} -> maximum end, :asc)
    |> Enum.find(fn %{"maximum_rank" => maximum} ->
      maximum > current_trophies
    end)
    |> Map.get(position)
  end
end

defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.Utils
  alias GameBackend.Users
  alias GameBackend.Users.Currencies
  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Matches.ArenaMatchResult

  def create_arena_match_results(results) do
    currency_config = Application.get_env(:game_backend, :currencies_config)

    Enum.reduce(results, Multi.new(), fn result, transaction_acc ->
      changeset = ArenaMatchResult.changeset(%ArenaMatchResult{}, result)
      {:ok, google_user} = Users.get_google_user(result["user_id"])

      amount_of_trophies = Currencies.get_amount_of_currency_by_name(google_user.user.id, "Trophies")

      amount =
        get_amount_of_trophies_to_modify(amount_of_trophies, result["position"], currency_config)

      Multi.insert(transaction_acc, {:insert, result["user_id"]}, changeset)
      |> Multi.run(
        {:add_trophies_to, result["user_id"]},
        fn _, _ ->
          Currencies.add_currency_by_name_and_game!(
            google_user.user.id,
            "Trophies",
            Utils.get_game_id(:curse_of_mirra),
            amount
          )
        end
      )
    end)
    |> Repo.transaction()
  end

  def get_amount_of_trophies_to_modify(current_trophies, position, currencies_config) do
    Enum.sort_by(
      get_in(currencies_config, ["ranking_system", "ranks"]),
      fn %{"maximum_rank" => maximum} -> maximum end,
      :asc
    )
    |> Enum.find(get_in(currencies_config, ["ranking_system", "infinite_rank"]), fn %{"maximum_rank" => maximum} ->
      maximum > current_trophies
    end)
    |> Map.get(position)
  end
end

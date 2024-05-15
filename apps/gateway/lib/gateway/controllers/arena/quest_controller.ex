defmodule Gateway.Curse.Controllers.Users.QuestController do
  @moduledoc """
    Controller to control currency changes in users
  """

  alias GameBackend.Users.Currencies.CurrencyCost
  alias GameBackend.Utils
  alias GameBackend.Users.Currencies
  alias GameBackend.CurseOfMirra.Quests
  GameBackend.Users.Currencies
  use Gateway, :controller

  def reroll_quest(conn, %{"quest_id" => quest_id}) do
    {:ok, quest_prices_attrs} =
      Application.app_dir(:game_backend, "priv/curse_of_mirra/quest_reroll_configuration.json")
      |> File.read()

    reroll_configurations = Jason.decode!(quest_prices_attrs, [{:keys, :atoms}])

    daily_quest =
      Quests.get_daily_quest(quest_id)

    amount_of_daily_quests =
      Quests.get_users_daily_quests(daily_quest.user_id)
      |> Enum.count()

    reroll_costs =
      reroll_configurations.costs
      |> Enum.map(fn currency_cost_params ->
        currency =
          Currencies.get_currency_by_name_and_game!(
            currency_cost_params.quest_currency_cost_name,
            Utils.get_game_id(:curse_of_mirra)
          )

        amount =
          (currency_cost_params.quest_base_cost + amount_of_daily_quests * reroll_configurations.reroll_multiplier)
          |> round()

        %CurrencyCost{currency_id: currency.id, amount: amount}
      end)

    if Currencies.can_afford(daily_quest.user_id, reroll_costs) do
      case Quests.reroll_quest(daily_quest, reroll_costs) do
        {:ok, %{insert_quest: _daily_quest}} ->
          conn
          |> send_resp(200, "added!")

        _ ->
          conn
          |> send_resp(400, "Error rerolling quest")
      end
    else
      conn
      |> send_resp(400, "You can't afford this reroll")
    end
  end
end

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
    reroll_configurations = Application.get_env(:game_backend, :quest_reroll_config)

    daily_quest =
      Quests.get_daily_quest(quest_id)

    amount_of_daily_quests =
      Quests.get_user_todays_daily_quests(daily_quest.user_id)
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

    cond do
      not Currencies.can_afford(daily_quest.user_id, reroll_costs) ->
        conn
        |> send_resp(400, "You can't afford this reroll")

      daily_quest.status == "rerolled" ->
        conn
        |> send_resp(400, "quest already rerolled")

      true ->
        case Quests.reroll_quest(daily_quest, reroll_costs) do
          {:ok, %{insert_quest: _daily_quest}} ->
            conn
            |> send_resp(200, "added!")

          _ ->
            conn
            |> send_resp(400, "Error rerolling quest")
        end
    end
  end
end

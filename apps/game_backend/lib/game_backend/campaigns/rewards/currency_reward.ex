defmodule GameBackend.Campaigns.Rewards.CurrencyReward do
  @moduledoc """
  The representation of a level reward that gives a currency to the user.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Campaigns.Level
  alias GameBackend.Users.Currencies.Currency

  schema "currency_rewards" do
    belongs_to(:currency, Currency)
    belongs_to(:level, Level)
    field(:amount, :integer)
    field(:afk_reward, :boolean)

    timestamps()
  end

  @doc false
  def changeset(currency_reward, attrs) do
    currency_reward
    |> cast(attrs, [:currency_id, :level_id, :amount, :afk_reward])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_required([:currency_id, :amount, :afk_reward])
  end
end

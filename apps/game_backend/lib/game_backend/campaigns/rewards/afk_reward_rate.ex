defmodule GameBackend.Campaigns.Rewards.AfkRewardRate do
  @moduledoc """
  The representation of a level reward that gives a currency to the user.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  alias GameBackend.Users.User
  alias GameBackend.Users.Currencies.Currency

  schema "afk_reward_rates" do
    belongs_to(:user, User)
    belongs_to(:currency, Currency)
    # Per second
    field(:rate, :integer)

    timestamps()
  end

  @doc false
  def changeset(afk_reward_rate, attrs) do
    afk_reward_rate
    |> cast(attrs, [:user_id, :currency_id, :rate])
    |> validate_number(:rate, greater_than_or_equal_to: 0)
    |> validate_required([:user_id, :currency_id, :rate])
  end

  @doc false
  def update_changeset(afk_reward_rate, attrs) do
    afk_reward_rate
    |> cast(attrs, [:rate])
    |> validate_required([:rate])
  end
end

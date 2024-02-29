defmodule GameBackend.Users.User do
  @moduledoc """
  Users.
  """

  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Campaigns.Rewards.AfkRewardRate
  alias GameBackend.Items.Item
  alias GameBackend.Units.Unit
  alias GameBackend.Users.Currencies.UserCurrency

  @derive {Jason.Encoder, only: [:id, :username, :currencies, :units, :items]}
  schema "users" do
    field(:game_id, :integer)
    field(:username, :string)
    field(:level, :integer)
    field(:experience, :integer)
    field(:last_afk_reward_claim, :utc_datetime)

    has_many(:currencies, UserCurrency)
    has_many(:units, Unit)
    has_many(:items, Item)
    has_many(:afk_reward_rates, AfkRewardRate)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:game_id, :username, :last_afk_reward_claim])
    |> put_change(:level, 1)
    |> put_change(:experience, 0)
    |> unique_constraint([:game_id, :username])
    |> validate_required([:game_id, :username])
  end

  def experience_changeset(user, attrs), do: user |> cast(attrs, [:experience, :level])
end

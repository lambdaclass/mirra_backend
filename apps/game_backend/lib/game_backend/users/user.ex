defmodule GameBackend.Users.User do
  @moduledoc """
  Users.
  """

  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Items.Item
  alias GameBackend.Units.Unit
  alias GameBackend.Users.Currencies.UserCurrency
  alias GameBackend.Campaigns.CampaignProgression

  schema "users" do
    field(:game_id, :integer)
    field(:username, :string)
    field(:level, :integer)
    field(:experience, :integer)

    has_many(:currencies, UserCurrency)
    has_many(:units, Unit)
    has_many(:items, Item)
    has_many(:campaign_progressions, CampaignProgression)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:game_id, :username])
    |> put_change(:level, 1)
    |> put_change(:experience, 0)
    |> unique_constraint([:game_id, :username])
    |> validate_required([:game_id, :username])
  end

  def reward_changeset(user, attrs) do
    user
    |> cast_assoc(:currencies)
    |> cast_assoc(:units)
    |> cast_assoc(:items)
  end

  def experience_changeset(user, attrs), do: user |> cast(attrs, [:experience, :level])
end

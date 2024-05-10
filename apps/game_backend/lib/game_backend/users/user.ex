defmodule GameBackend.Users.User do
  @moduledoc """
  Users.
  """

  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Campaigns.SuperCampaignProgress
  alias GameBackend.Items.Item
  alias GameBackend.Units.Unit
  alias GameBackend.Users.Currencies.UserCurrency
  alias GameBackend.Users.KalineTreeLevel
  alias GameBackend.Users.GoogleUser

  schema "users" do
    field(:game_id, :integer)
    field(:username, :string)
    field(:level, :integer)
    field(:experience, :integer)
    field(:last_afk_reward_claim, :utc_datetime)
    field(:last_daily_reward_claim_at, :utc_datetime)
    field(:last_daily_reward_claim, :string)
    field(:profile_picture, :string)

    belongs_to(:kaline_tree_level, KalineTreeLevel)
    belongs_to(:google_user, GoogleUser)

    has_many(:currencies, UserCurrency)
    has_many(:units, Unit, preload_order: [desc: :level])
    has_many(:items, Item)
    has_many(:super_campaign_progresses, SuperCampaignProgress)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :game_id,
      :username,
      :last_afk_reward_claim,
      :last_daily_reward_claim_at,
      :last_daily_reward_claim,
      :kaline_tree_level_id,
      :level,
      :experience,
      :profile_picture,
      :google_user_id
    ])
    |> unique_constraint([:game_id, :username])
    |> assoc_constraint(:google_user)
    |> validate_required([:game_id, :username, :kaline_tree_level_id])
  end

  def experience_changeset(user, attrs), do: user |> cast(attrs, [:experience, :level])

  def kaline_tree_level_changeset(user, attrs) do
    user
    |> cast(attrs, [:kaline_tree_level])
  end
end

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
  alias GameBackend.Users.DungeonSettlementLevel
  alias GameBackend.Users.KalineTreeLevel
  alias GameBackend.Users.GoogleUser
  alias GameBackend.Quests.DailyQuest

  schema "users" do
    field(:game_id, :integer)
    field(:username, :string)
    field(:level, :integer)
    field(:experience, :integer)
    field(:last_kaline_afk_reward_claim, :utc_datetime)
    field(:last_dungeon_afk_reward_claim, :utc_datetime)
    field(:profile_picture, :string)

    belongs_to(:dungeon_settlement_level, DungeonSettlementLevel)
    belongs_to(:kaline_tree_level, KalineTreeLevel)
    belongs_to(:google_user, GoogleUser)

    has_many(:currencies, UserCurrency)
    has_many(:units, Unit, preload_order: [desc: :level])
    has_many(:items, Item)
    has_many(:daily_quests, DailyQuest)
    has_many(:super_campaign_progresses, SuperCampaignProgress)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :game_id,
      :username,
      :last_kaline_afk_reward_claim,
      :last_dungeon_afk_reward_claim,
      :dungeon_settlement_level_id,
      :kaline_tree_level_id,
      :level,
      :experience,
      :profile_picture,
      :google_user_id
    ])
    |> unique_constraint([:game_id, :username])
    |> assoc_constraint(:google_user)
    |> validate_required([:game_id, :username])
  end

  def experience_changeset(user, attrs), do: user |> cast(attrs, [:experience, :level])

  def kaline_tree_level_changeset(user, attrs) do
    user
    |> cast(attrs, [:kaline_tree_level])
  end
end

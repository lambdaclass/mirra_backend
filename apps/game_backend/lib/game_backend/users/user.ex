defmodule GameBackend.Users.User do
  @moduledoc """
  Users.
  """

  use GameBackend.Schema
  import Ecto.Changeset
  alias GameBackend.Matches.ArenaMatchResult
  alias GameBackend.Campaigns.SuperCampaignProgress
  alias GameBackend.Items.Item
  alias GameBackend.Quests.UserQuest
  alias GameBackend.Units.Unit

  alias GameBackend.Users.{
    Currencies.UserCurrency,
    Currencies.UserCurrencyCap,
    DungeonSettlementLevel,
    KalineTreeLevel,
    GoogleUser,
    Unlock
  }

  @derive {Jason.Encoder, only: [:username, :currencies, :prestige]}
  schema "users" do
    field(:game_id, :integer)
    field(:username, :string)
    field(:level, :integer)
    field(:experience, :integer)
    field(:last_daily_reward_claim_at, :utc_datetime)
    field(:last_daily_reward_claim, :string)
    field(:last_kaline_afk_reward_claim, :utc_datetime)
    field(:last_dungeon_afk_reward_claim, :utc_datetime)
    field(:profile_picture, :string)
    field(:prestige, :integer, virtual: true)

    belongs_to(:dungeon_settlement_level, DungeonSettlementLevel)
    belongs_to(:kaline_tree_level, KalineTreeLevel)
    belongs_to(:google_user, GoogleUser)

    has_many(:arena_match_results, ArenaMatchResult)
    has_many(:currencies, UserCurrency)
    has_many(:units, Unit, preload_order: [desc: :level])
    has_many(:items, Item)
    has_many(:user_quests, UserQuest)
    has_many(:super_campaign_progresses, SuperCampaignProgress)
    has_many(:unlocks, Unlock)
    has_many(:currency_caps, UserCurrencyCap)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :game_id,
      :username,
      :last_daily_reward_claim_at,
      :last_daily_reward_claim,
      :last_kaline_afk_reward_claim,
      :last_dungeon_afk_reward_claim,
      :dungeon_settlement_level_id,
      :kaline_tree_level_id,
      :level,
      :experience,
      :profile_picture,
      :google_user_id
    ])
    |> cast_assoc(:unlocks)
    |> assoc_constraint(:google_user)
    |> validate_required([:game_id, :username])
    |> cast_assoc(:units, with: &GameBackend.Units.Unit.changeset/2)
    |> game_validations()
  end

  def experience_changeset(user, attrs), do: user |> cast(attrs, [:experience, :level])

  def kaline_tree_level_changeset(user, attrs) do
    user
    |> cast(attrs, [:kaline_tree_level])
  end

  defp game_validations(changeset) do
    curse_of_mirra_game_id = GameBackend.Utils.get_game_id(:curse_of_mirra)

    case get_field(changeset, :game_id) do
      ^curse_of_mirra_game_id ->
        changeset
        |> validate_length(:username, min: 2, max: 9)

      _ ->
        changeset
    end
  end
end

defmodule GameBackend.Users.AfkRewardIncrement do
  @moduledoc """
  The representation of a Kaline Tree level up reward, that increments the user's AFK rewards.
  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "afk_reward_increments" do
    belongs_to(:kaline_tree_level, GameBackend.Users.KalineTreeLevel)
    belongs_to(:currency, GameBackend.Users.Currencies.Currency)
    field(:amount, :integer)

    timestamps()
  end

  @doc false
  def changeset(afk_reward_increment, attrs) do
    afk_reward_increment
    |> cast(attrs, [:kaline_tree_level_id, :currency_id, :amount])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
    |> validate_required([:kaline_tree_level_id, :currency_id, :amount])
  end
end

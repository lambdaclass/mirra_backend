defmodule GameBackend.Matches.ArenaMatchResult do
  @moduledoc """
  Match results for Arena games
  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "arena_match_results" do
    field(:result, :string)
    field(:kills, :integer)
    field(:deaths, :integer)
    field(:character, :string)
    timestamps()

    belongs_to(:user, GameBackend.Users.GoogleUser)
  end

  def changeset(match_result, attrs) do
    match_result
    |> cast(attrs, [:result, :kills, :deaths, :character, :user_id])
    |> validate_required([:result, :kills, :deaths, :character, :user_id])
    |> validate_number(:kills, greater_than_or_equal_to: 0)
    |> validate_number(:deaths, greater_than_or_equal_to: 0)
    |> validate_inclusion(:result, ["win", "loss", "abandon"])
    |> validate_inclusion(:character, ["h4ck", "muflus", "uma"])
  end
end

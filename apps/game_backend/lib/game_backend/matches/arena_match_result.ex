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
    field(:match_id, Ecto.UUID)
    field(:position, :integer)
    timestamps()

    belongs_to(:google_user, GameBackend.Users.GoogleUser)
  end

  @required [
    :result,
    :kills,
    :deaths,
    :character,
    :match_id,
    :google_user_id,
    :position
  ]

  @permitted [] ++ @required

  def changeset(match_result, attrs) do
    match_result
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> validate_number(:kills, greater_than_or_equal_to: 0)
    |> validate_number(:deaths, greater_than_or_equal_to: 0)
    |> validate_inclusion(:result, ["win", "loss", "abandon"])
    ## TODO: This enums should actually be read from config
    ##    https://github.com/lambdaclass/mirra_backend/issues/601
    |> validate_inclusion(:character, ["h4ck", "muflus", "uma"])
    |> foreign_key_constraint(:user_id)
  end
end

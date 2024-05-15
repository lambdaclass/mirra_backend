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
    field(:damage_done, :integer)
    field(:damage_taken, :integer)
    field(:health_healed, :integer)
    field(:killed_by, :string)
    field(:killed_by_bot, :boolean)
    field(:duration_ms, :integer)
    timestamps()

    belongs_to(:user, GameBackend.Users.GoogleUser)
  end

  @required [
    :result,
    :kills,
    :deaths,
    :character,
    :match_id,
    :user_id,
    :position,
    :damage_done,
    :damage_taken,
    :health_healed,
    :killed_by_bot,
    :duration_ms
  ]

  @permitted [:killed_by] ++ @required

  def changeset(match_result, attrs) do
    match_result
    |> cast(attrs, @permitted)
    |> validate_required(@required)
    |> validate_number(:kills, greater_than_or_equal_to: 0)
    |> validate_number(:deaths, greater_than_or_equal_to: 0)
    |> validate_number(:damage_done, greater_than_or_equal_to: 0)
    |> validate_number(:damage_taken, greater_than_or_equal_to: 0)
    |> validate_number(:health_healed, greater_than_or_equal_to: 0)
    |> validate_number(:duration_ms, greater_than_or_equal_to: 0)
    |> validate_inclusion(:result, ["win", "loss", "abandon"])
    ## TODO: This enums should actually be read from config
    ##    https://github.com/lambdaclass/mirra_backend/issues/601
    |> validate_inclusion(:character, ["h4ck", "muflus", "uma", "valtimer", "otix"])
    |> validate_inclusion(:killed_by, ["h4ck", "muflus", "uma", "valtimer", "otix", "zone"])
    |> foreign_key_constraint(:user_id)
  end
end

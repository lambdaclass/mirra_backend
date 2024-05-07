defmodule GameBackend.Matches.ArenaMatchStatistics do
  @moduledoc """
  Match results for Arena games
  """

  use GameBackend.Schema
  import Ecto.Changeset

  schema "arena_match_statistics" do
    field(:match_id, Ecto.UUID)
    field(:data, :binary)
    timestamps()
  end

  def changeset(match_result, attrs) do
    match_result
    |> cast(attrs, [:match_id, :data])
    |> validate_required([:match_id, :data])
  end
end

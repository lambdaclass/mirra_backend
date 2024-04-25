defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias GameBackend.Repo
  alias GameBackend.Matches.ArenaMatchResult

  def create_arena_match_result(attrs) do
    %ArenaMatchResult{}
    |> ArenaMatchResult.changeset(attrs)
    |> Repo.insert()
  end
end

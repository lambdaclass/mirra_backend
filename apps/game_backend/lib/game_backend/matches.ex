defmodule GameBackend.Matches do
  @moduledoc """
  Matches
  """
  alias Ecto.Multi
  alias GameBackend.Repo
  alias GameBackend.Matches.ArenaMatchResult

  def create_arena_match_results(match_id, results) do
    transaction = Multi.new()

    {transaction, _} =
      Enum.reduce(results, {transaction, 1}, fn result, {transaction_acc, idx} ->
        attrs = Map.put(result, "match_id", match_id)
        changeset = ArenaMatchResult.changeset(%ArenaMatchResult{}, attrs)
        transaction_acc = Multi.insert(transaction_acc, {:insert, idx}, changeset)
        {transaction_acc, idx + 1}
      end)

    Repo.transaction(transaction)
  end
end

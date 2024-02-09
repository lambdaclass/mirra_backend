defmodule GameBackend.Transaction do
  @moduledoc """
  Module for exponsing transactions to game applications.
  """

  alias GameBackend.Repo

  def run(transaction) do
    Repo.transaction(transaction)
  end
end

defmodule GameBackend.Transaction do
  @moduledoc """
  Module for exposing transactions to game applications.
  """

  alias GameBackend.Repo

  @doc """
  Run a multi transaction.
  """
  def run(multi) do
    Repo.transaction(multi)
  end
end

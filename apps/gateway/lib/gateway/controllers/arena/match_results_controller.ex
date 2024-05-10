defmodule Gateway.Controllers.Arena.MatchResultsController do
  @moduledoc """
  Controller for Arena requests involving match results.
  """

  use Gateway, :controller
  alias GameBackend.Matches

  def create(conn, %{"results" => results}) do
    case Matches.create_arena_match_results(results) do
      {:ok, _match_result} ->
        send_resp(conn, 201, "")

      {:error, _insert_op, %Ecto.Changeset{} = changeset, _} ->
        ## TODO: properly handle errors with a better error message
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

        conn
        |> put_status(422)
        |> json(%{status: 422, message: "Unprocessable Entity", errors: errors})
    end
  end
end

defmodule Gateway.Controllers.Arena.MatchResultsController do
  @moduledoc """
  Controller for Arena requests involving match results.
  """

  use Gateway, :controller
  alias GameBackend.Matches

  def create(conn, params) do
    IO.inspect(params)
    case Matches.create_arena_match_result(params) do
      {:ok, _match_result} ->
        send_resp(conn, 201, "")

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

        conn
        |> put_status(422)
        |> json(%{
          error: %{
            status: 422,
            message: "Unprocessable Entity",
            errors: errors
          }
        })
    end
  end

end

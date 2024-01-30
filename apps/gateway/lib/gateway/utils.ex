defmodule Gateway.Utils do
  @moduledoc false

  use Gateway, :controller

  def format_response(result, conn) do
    case result do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      {:ok, result} ->
        json(conn, result)

      result ->
        json(conn, result)
    end
  end
end

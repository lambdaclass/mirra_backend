defmodule GatewayWeb.Utils do
  @moduledoc false

  use GatewayWeb, :controller

  def format_response(result, conn) do
    case result do
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(reason)

      result ->
        json(conn, result)
    end
  end
end

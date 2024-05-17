defmodule Gateway.Controllers.FallbackController do
  @moduledoc """
  Controller used as fallback to handle errors.
  """
  use Gateway, :controller

  def call(conn, {:error, :not_found}) do
    send_resp(conn, 404, Jason.encode!(%{"error" => "not found"}))
  end

  def call(conn, {:error, %Ecto.Changeset{}}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "failed to update"}))
  end

  def call(conn, {:error, :already_claimed}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "already claimed"}))
  end

  def call(conn, {:error, :invalid_reward}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "invalid reward"}))
  end

  def call(conn, {:error, failed_operation, _failed_value, _changes_so_far}) when is_binary(failed_operation) do
    send_resp(conn, 400, Jason.encode!(%{"error" => failed_operation}))
  end

  def call(conn, {:error, failed_operation, _failed_value, _changes_so_far}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => Atom.to_string(failed_operation)}))
  end
end

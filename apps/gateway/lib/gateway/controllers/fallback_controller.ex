defmodule Gateway.Controllers.FallbackController do
  @moduledoc """
  Controller used as fallback to handle errors.
  """
  use Gateway, :controller

  def call(conn, {:error, error_message}) when is_binary(error_message) do
    send_resp(conn, 404, Jason.encode!(%{"error" => error_message}))
  end

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

  def call(conn, {:error, :cant_afford}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "cant afford"}))
  end

  def call(conn, {:error, :quest_rerolled}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "quest already rerolled"}))
  end

  def call(conn, {:error, :item_not_found}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "item not found"}))
  end

  def call(conn, {:error, :item_not_owned}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "item not owned"}))
  end

  def call(conn, {:error, :unit_not_owned}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "unit not owned"}))
  end

  def call(conn, {:error, :character_cannot_equip}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "character cannot equip item"}))
  end

  def call(conn, {:can_afford, false}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "user cannot afford the cost"}))
  end

  def call(conn, {:can_select_skin?, false}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "user cannot select the skin"}))
  end

  def call(conn, {:already_bought_skin?, true}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "user has the skin already"}))
  end

  def call(conn, {:error, :quest_type_not_implemented}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "quest type not implemented yet"}))
  end

  def call(conn, {:error, :unfinished_quest}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "quest unfinished"}))
  end

  def call(conn, {:error, :unexistent_user_quest}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "the user doesn't have that quest"}))
  end

  def call(conn, {:error, _failed_operation, :not_found, _changes_so_far}) do
    send_resp(conn, 404, Jason.encode!(%{"error" => "not found"}))
  end

  def call(conn, {:error, failed_operation, _failed_value, _changes_so_far}) when is_binary(failed_operation) do
    send_resp(conn, 400, Jason.encode!(%{"error" => failed_operation}))
  end

  def call(conn, {:error, failed_operation, _failed_value, _changes_so_far}) do
    send_resp(conn, 400, Jason.encode!(%{"error" => Atom.to_string(failed_operation)}))
  end

  def call(conn, _) do
    send_resp(conn, 400, Jason.encode!(%{"error" => "Bad request"}))
  end
end

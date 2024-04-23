defmodule GameClient.Users do
  @moduledoc """
  false
  """

  def get_user_email(user_id) do
    {:ok, %Finch.Response{body: body}} =
      Finch.build(:get, "http://localhost:4001/users/#{user_id}")
      |> Finch.request(GameClient.Finch)

    body
  end
end

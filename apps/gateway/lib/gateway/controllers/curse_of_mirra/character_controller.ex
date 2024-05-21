defmodule Gateway.Controllers.CurseOfMirra.CharacterController do
  @moduledoc """
  Controller for Character modifications.
  """
  use Gateway, :controller
  alias GameBackend.Utils

  action_fallback Gateway.Controllers.FallbackController

  def get_characters_config(conn, _params) do
    case Utils.get_characters_config() do
      nil -> {:error, :not_found}
      characters_config -> send_resp(conn, 200, Jason.encode!(characters_config))
    end
  end
end

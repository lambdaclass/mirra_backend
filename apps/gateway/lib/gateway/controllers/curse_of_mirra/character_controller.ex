defmodule Gateway.Controllers.CurseOfMirra.CharacterController do
  @moduledoc """
  Controller for Character modifications.
  """
  use Gateway, :controller
  alias GameBackend.Units.Characters

  action_fallback Gateway.Controllers.FallbackController

  def get_characters_config(conn, _params) do
    case Characters.get_curse_characters() do
      [] -> {:error, :not_found}
      characters -> send_resp(conn, 200, Jason.encode!(Characters.encode_characters(characters)))
    end
  end
end

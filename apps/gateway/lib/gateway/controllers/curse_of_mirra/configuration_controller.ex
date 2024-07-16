defmodule Gateway.Controllers.CurseOfMirra.ConfigurationController do
  @moduledoc """
  Controller for Curse of Mirra Configurations
  """
  use Gateway, :controller
  alias GameBackend.Configuration

  action_fallback Gateway.Controllers.FallbackController

  def get_map_configuration(conn, _params) do
    map_configuration = Configuration.get_latest_map_configuration()
    send_resp(conn, 200, Jason.encode!(map_configuration))
  end
end

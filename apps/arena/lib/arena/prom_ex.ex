defmodule Arena.PromEx do
  @moduledoc """
  This module integrates the PromEx library. It sets up PromEx plugins and pre-built dashboards for the node.
  """
  use PromEx, otp_app: :arena

  @impl true
  def plugins() do
    [
      PromEx.Plugins.Beam
    ]
  end
end

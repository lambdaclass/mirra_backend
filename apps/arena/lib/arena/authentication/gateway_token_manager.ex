defmodule Arena.Authentication.GatewayTokenManager do
  @moduledoc """
  Module responsible to verify and validate the JWT emitted by gateway app.
  """
  use Joken.Config, default_signer: nil

  @impl Joken.Config
  def token_config do
    default_exp = Application.get_env(:joken, :default_exp)
    default_claims(default_exp: default_exp)
  end
end

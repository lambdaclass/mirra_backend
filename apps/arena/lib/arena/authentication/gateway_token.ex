defmodule Arena.Authentication.GatewayToken do
  @moduledoc """
  Module responsible to verify and validate the JWT emitted by gateway app.
  """
  alias Arena.Authentication.GatewaySigner
  use Joken.Config, default_signer: nil

  @impl Joken.Config
  def token_config do
    default_exp = Application.get_env(:joken, :default_exp)
    default_claims(default_exp: default_exp)
  end

  @impl Joken.Hooks
  def before_verify(_hook_options, {token, _signer}) do
    signer = GatewaySigner.signer()
    {:cont, {token, signer}}
  end
end

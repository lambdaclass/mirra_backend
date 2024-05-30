defmodule Gateway.Auth.GatewayTokenManager do
  @moduledoc """
  Module responsible to verify and validate the JWT emitted by gatewat app.
  """
  alias GameBackend.Users.User

  use Joken.Config

  def generate_user_token(%User{id: id}) do
    {:ok, token, _claims} = generate_and_sign(%{"sub" => id})
    token
  end

  @impl Joken.Config
  def token_config do
    default_claims(skip: [:aud, :iss])
  end
end

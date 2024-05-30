defmodule Gateway.Auth.TokenManager do
  @moduledoc """
  Module responsible to verify and validate the JWT emitted by gateway app.
  """
  alias GameBackend.Users.User

  use Joken.Config

  def generate_user_token(%User{id: id}) do
    {:ok, token, _claims} = generate_and_sign(%{"sub" => id})
    token
  end

  @impl Joken.Config
  def token_config do
    default_exp = Application.get_env(:joken, :default_exp)
    default_claims(skip: [:aud, :iss], default_exp: default_exp)
  end
end

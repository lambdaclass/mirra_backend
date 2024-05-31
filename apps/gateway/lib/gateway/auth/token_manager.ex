defmodule Gateway.Auth.TokenManager do
  @moduledoc """
  Module responsible to verify and validate the JWT emitted by gateway app.
  """
  alias GameBackend.Users.User

  use Joken.Config

  def generate_user_token(%User{id: id}, client_id) do
    hash_client_id =
      :crypto.hash(:sha256, client_id)
      |> Base.url_encode64()

    extra_claims = %{"sub" => id, "dev" => hash_client_id}
    {:ok, token, _claims} = generate_and_sign(extra_claims)
    token
  end

  @impl Joken.Config
  def token_config do
    default_exp = Application.get_env(:joken, :default_exp)
    default_claims(skip: [:aud, :iss], default_exp: default_exp)
  end
end

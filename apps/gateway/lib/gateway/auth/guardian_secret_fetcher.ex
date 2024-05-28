defmodule Gateway.Auth.GuardianSecretFetcher do
  @behaviour Guardian.Token.Jwt.SecretFetcher

  @impl true
  def fetch_signing_secret(_module, _opts) do
    IO.inspect("fetching signing secret")
    secret =
      Application.get_env(:gateway, Gateway.Auth.Guardian)[:jwt_private_key]
      |> JOSE.JWK.from_openssh_key()

    {:ok, secret}
  end

  @impl true
  def fetch_verifying_secret(_module, _headers, _opts) do
    IO.inspect("fetching verifying secret")
    secret =
      Application.get_env(:gateway, Gateway.Auth.Guardian)[:jwt_private_key]
      |> JOSE.JWK.from_openssh_key()
      |> JOSE.JWK.to_public()

    {:ok, secret}
  end
end

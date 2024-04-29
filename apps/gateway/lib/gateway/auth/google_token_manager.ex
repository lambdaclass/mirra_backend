defmodule Gateway.Auth.GoogleTokenManager do
  @moduledoc """
  Module responsible to verify and validate the Google TokenIDs.
  Its logic has been done following the GoogleCertificates docs:
  https://hexdocs.pm/google_certs/readme.html
  """

  use Joken.Config, default_signer: nil

  add_hook(Gateway.Auth.GoogleVerifyHook)

  @impl Joken.Config
  def token_config do
    issuer = Application.get_env(:joken, :issuer)
    audience = Application.get_env(:joken, :audience)

    default_claims(skip: [:aud, :iss, :exp])
    |> add_claim("iss", nil, &(&1 == issuer))
    |> add_claim("aud", nil, &(&1 == audience))
    |> add_claim("exp", nil, &(&1 > current_time()))
  end
end

defmodule Gateway.Auth.GoogleTokenManager do
  @moduledoc """
  Module responsible to verify and validate the Google TokenIDs.
  Its logic has been done following the GoogleCertificates docs:
  https://hexdocs.pm/google_certs/readme.html
  """

  use Joken.Config, default_signer: nil

  @iss "https://accounts.google.com"

  defp aud, do: System.get_env("GOOGLE_CLIENT_ID")

  add_hook(Gateway.Auth.GoogleVerifyHook)

  @impl Joken.Config
  def token_config do
    default_claims(skip: [:aud, :iss, :exp])
    |> add_claim("iss", nil, &(&1 == @iss))
    |> add_claim("aud", nil, &(&1 == aud()))
    |> add_claim("exp", nil, &(&1 > current_time()))
  end
end

defmodule Arena.Authentication.GatewaySigner do

  def signer() do
    ## TODO: this should be a gen_server fetching from gateway and recreating this
    jwk = %{
      "crv" => "Ed25519",
      "kid" => "arena@gateway.mirra.dev",
      "kty" => "OKP",
      "x" => "1YLJHEHTRj4HD_VCSMAOgAdRVJ7wsjtfXQoVWNxBbmU"
    }
    Joken.Signer.create("Ed25519", jwk)
  end
end

defmodule Gateway.Auth.GoogleVerifyHook do
  @moduledoc """
  Module that implements a Joken Hook to do several operations before running any google token verification.
  """

  use Joken.Hooks

  @impl true
  def before_verify(_options, {jwt, %Joken.Signer{} = _signer}) do
    with {:ok, %{"kid" => kid}} <- Joken.peek_header(jwt),
         {:ok, algorithm, key} <- GoogleCerts.fetch(kid) do
      {:cont, {jwt, Joken.Signer.create(algorithm, key)}}
    else
      _error -> {:halt, {:error, :no_signer}}
    end
  end
end

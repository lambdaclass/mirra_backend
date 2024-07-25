defmodule Arena.Authentication.GatewaySigner do
  @moduledoc """
  GenServer that calls gateway to fetch public key used for JWT authentication
  The public key is converted into a Joken.Signer and cached for internal app usage
  """
  use GenServer

  def get_signer() do
    GenServer.call(__MODULE__, :get_signer)
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Process.send_after(self(), :fetch_signer, 500)
    {:ok, %{}}
  end

  @impl true
  def handle_call(:get_signer, _, state) do
    {:reply, state.signer, state}
  end

  @impl true
  def handle_info(:fetch_signer, state) do
    gateway_url = Application.get_env(:arena, :gateway_url)

    result =
      Finch.build(:get, "#{gateway_url}/auth/public-key", [{"content-type", "application/json"}])
      |> Finch.request(Arena.Finch)

    case result do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        Process.send_after(self(), :fetch_signer, 3_600_000)
        %{"jwk" => jwk} = Jason.decode!(body)
        signer = Joken.Signer.create("Ed25519", jwk)
        {:noreply, Map.put(state, :signer, signer)}

      _else_error ->
        Process.send_after(self(), :fetch_signer, 5_000)
        {:noreply, state}
    end
  end
end

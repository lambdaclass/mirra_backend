defmodule BotManager.TokenFetcher do
  @moduledoc """
  GenServer that calls gateway to create and refresh a JWT token used by the bots
  """
  use GenServer

  def get_auth() do
    GenServer.call(__MODULE__, :get_auth)
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Process.send_after(self(), :fetch_token, 500)
    {:ok, %{}}
  end

  @impl true
  def handle_call(:get_auth, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:fetch_token, state) do
    gateway_url = Application.get_env(:bot_manager, :gateway_url)
    secret = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    payload = Jason.encode!(%{"bot_secret" => secret})

    result =
      Finch.build(:post, "#{gateway_url}/auth/generate-bot-token", [{"content-type", "application/json"}], payload)
      |> Finch.request(BotManager.Finch)

    case result do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        Process.send_after(self(), :fetch_token, 1_800_000)
        %{"token" => token} = Jason.decode!(body)
        {:noreply, %{token: token, secret: secret}}

      _else_error ->
        Process.send_after(self(), :fetch_token, 5_000)
        {:noreply, state}
    end
  end
end

defmodule BotManager.Bot do
  require Logger
  use GenServer

  @message_delay_ms 300

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  ## Callbacks

  @impl true
  def init(bot_config) do
    IO.inspect(bot_config, label: "aber bot config")

    {:ok, game_socket_handler_pid} =
      BotManager.GameSocketHandler.start_link(
        bot_config["player_id"],
        bot_config["game_pid"]
      )

    Logger.info("intializing bot #{self() |> :erlang.term_to_binary() |> Base58.encode()}")
    # send(self(), :random_action)
    {:ok, bot_config}
  end

  # @impl true
  # def handle_info(:random_action, state) do
  #   Process.send_after(self(), :random_action, @message_delay_ms)
  #   timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)

  #   GameUpdater.move(
  #     state["game_pid"],
  #     state["bot_id"],
  #     {:rand.uniform(), :rand.uniform()},
  #     timestamp
  #   )

  #   {:noreply, state}
  # end
end

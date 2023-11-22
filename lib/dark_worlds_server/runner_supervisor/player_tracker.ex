defmodule DarkWorldsServer.RunnerSupervisor.PlayerTracker do
  @table :player_tracker
  @persistent_term_key {__MODULE__, :runtime_id}

  def create_table() do
    runtime_id = DateTime.utc_now(Calendar.ISO) |> DateTime.to_unix(:millisecond)

    :persistent_term.put(@persistent_term_key, runtime_id)
    :ets.new(@table, [:set, :public, :named_table])
  end

  def add_player_game(client_id, game_player_id, game_pid) when is_binary(client_id) do
    runtime_id = :persistent_term.get(@persistent_term_key)
    true = :ets.insert(@table, {client_id, runtime_id, game_pid, game_player_id})
  end

  def get_player_game(client_id) when is_binary(client_id) do
    with runtime_id <- :persistent_term.get(@persistent_term_key),
         [{^client_id, ^runtime_id, game_pid, game_player_id}] <- :ets.lookup(@table, client_id),
         true <- Process.alive?(game_pid) do
      {game_pid, game_player_id}
    else
      _ -> nil
    end
  end

  def remove_player(client_id) do
    :ets.delete(@table, client_id)
  end
end

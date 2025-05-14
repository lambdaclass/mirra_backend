defmodule Arena.PromExPlugin do
  @moduledoc """
  This module defines our custom PromEx plugin.
  It contains all our custom metrics that are displayed on the grafana dashboard.
  """

  use PromEx.Plugin

  @impl true
  def event_metrics(_opts) do
    [
      Event.build(:game_metrics, [
        sum("arena.game.count", description: "Number of games in progress"),
        distribution("arena.game.tick.duration",
          description: "Time spent on running a game update tick",
          unit: {:native, :millisecond},
          reporter_options: [buckets: [0, 5, 10, 30, 100, 1_000]]
        ),
        sum("arena.clients.count", description: "Number of clients (websockets) connected"),
        sum([:bots, :count], description: "Amount of active bots"),
        distribution([:game_updater, :broadcast, :binary_size],
          reporter_options: [buckets: [0, 10, 100, 1_000, 10_000, 100_000]],
          description: "Size of encoded game update broadcast in Megabits"
        )
      ]),
      Event.build(:vm_metrics, [
        last_value("vm.memory.total", unit: {:byte, :kilobyte}),
        last_value("vm.total_run_queue_lengths.total", description: "Total run queue length of CPU and IO schedulers"),
        last_value("vm.total_run_queue_lengths.cpu", description: "Run queue length of CPU scheduler"),
        last_value("vm.total_run_queue_lengths.io", description: "Run queue length of IO scheduler")
      ])
    ]
  end

  @impl true
  def polling_metrics(_opts) do
    poll_rate = 10_000

    [
      Polling.build(:periodic_measurements, poll_rate, {Arena.Utils, :periodic_measurements, []}, [
        # All BEAM processes message queues
        last_value([:vm, :message_queue, :length], tags: [:process]),
        # Bots
        distribution([:bots, :message_queue, :length],
          reporter_options: [buckets: [0, 10, 100, 1_000, 10_000, 100_000]]
        ),
        # GameUpdater
        distribution([:game_updater, :message_queue, :length],
          reporter_options: [buckets: [0, 10, 100, 1_000, 10_000, 100_000]]
        ),
        # OS

        last_value([:os, :cpu_usage], []),
        last_value([:os, :system_total_memory], unit: {:byte, :megabyte}),
        last_value([:os, :free_memory], unit: {:byte, :megabyte}),
        last_value([:os, :buffered_memory], unit: {:byte, :megabyte}),
        last_value([:os, :cached_memory], unit: {:byte, :megabyte}),
        last_value([:os, :total_swap], unit: {:byte, :megabyte}),
        last_value([:os, :free_swap], unit: {:byte, :megabyte})
      ])
    ]
  end
end

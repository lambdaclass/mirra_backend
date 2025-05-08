defmodule Arena.PromExPlugin do
  @moduledoc """
  This module defines our custom PromEx plugin.
  It contains all our custom metrics that are displayed on the graphana dashboard.
  """

  use PromEx.Plugin

  @impl true
  def event_metrics(_opts) do
    [
      Event.build(:game_metrics, [
        sum("arena.game.count", description: "Number of games in progress"),
        ## TODO: this metric is an attempt to gather data to properly set the buckets for the distribution metric below
        last_value("arena.game.tick.duration_measure",
          description: "Last game tick duration",
          unit: {:native, :nanosecond}
        ),
        ## TODO: Buckets probably need to be redefined, currently they all fall under the first bucket
        distribution("arena.game.tick.duration",
          description: "Time spent on running a game tick",
          unit: {:native, :nanosecond},
          reporter_options: [buckets: [7_500_000.0, 15_000_000.0, 22_500_000.0]]
        ),
        sum("arena.clients.count", description: "Number of clients (websockets) connected")
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
      Polling.build(:periodic_measurements, poll_rate, {Arena.Utils, :message_queue_lengths, []}, [
        # All BEAM processes message queues
        last_value([:vm, :message_queue, :length], tags: [:process]),
        # Bots
        distribution([:bots, :message_queue, :length],
          reporter_options: [buckets: [0, 10, 100, 1_000, 10_000, 100_000]]
        ),
        # GameUpdater
        distribution([:game_updater, :message_queue, :length],
          reporter_options: [buckets: [0, 10, 100, 1_000, 10_000, 100_000]]
        )
      ])
    ]
  end
end

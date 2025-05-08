defmodule ArenaWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()},
      {TelemetryMetricsPrometheus, [metrics: metrics(), port: Application.get_env(:arena, :metrics_endpoint_port)]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # VM Metrics
      last_value("vm.memory.total", unit: {:byte, :kilobyte}),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io"),

      # All BEAM processes message queues
      last_value([:vm, :message_queue, :length], tags: [:process]),

      # Bots
      summary([:bots, :message_queue, :length]),
      distribution([:bots, :message_queue, :length], reporter_options: [buckets: [0, 10, 100, 1000, 10000, 100_000]]),
      sum([:bots, :count], description: "Amount of active bots"),

      # GameUpdater
      summary([:game_updater, :message_queue, :length]),
      distribution([:game_updater, :message_queue, :length],
        reporter_options: [buckets: [0, 10, 100, 1000, 10000, 100_000]]
      ),

      ## Arena (game) metrics
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
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {ArenaWeb, :count_users, []}
      {Arena.Utils, :message_queue_lengths, []}
    ]
  end
end

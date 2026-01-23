defmodule SiwappWeb.Telemetry do
  @moduledoc false
  use Supervisor
  import Telemetry.Metrics

  @spec start_link(list) :: {:ok, pid()} | {:error, {:already_started, pid()} | term()}
  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl Supervisor
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: :timer.seconds(10)},
      {TelemetryMetricsPrometheus, [metrics: metrics()]}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @spec metrics :: [Telemetry.Metrics.Summary.t()]
  def metrics do
    [
      last_value("vm.memory.total", unit: :byte),
      last_value("vm.memory.processes", unit: :byte),
      last_value("vm.memory.processes_used", unit: :byte),
      last_value("vm.memory.system", unit: :byte),
      last_value("vm.memory.atom", unit: :byte),
      last_value("vm.memory.atom_used", unit: :byte),
      last_value("vm.memory.binary", unit: :byte),
      last_value("vm.memory.code", unit: :byte),
      last_value("vm.memory.ets", unit: :byte),

      # CPU & IO metrics
      last_value("vm.cpu.usage"),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io"),

      # Count metrics
      last_value("vm.system_limits.process"),
      last_value("vm.system_counts.process_count"),
      last_value("vm.system_counts.atom_count"),
      last_value("vm.system_counts.port_count"),

      # Phoenix metrics
      counter("phoenix.endpoint.count",
        event_name: [:phoenix, :endpoint, :stop],
        measurement: :duration,
        tag_values: fn %{conn: conn} -> %{status: conn.status} end,
        tags: [:status]
      ),
      distribution("phoenix.endpoint.stop.duration",
        reporter_options: [
          buckets: [0.01, 0.02, 0.03, 0.05, 0.1, 0.5, 1]
        ],
        unit: {:native, :second}
      ),
      distribution("phoenix.router_dispatch.stop.duration",
        reporter_options: [
          buckets: [0.01, 0.02, 0.03, 0.05, 0.1, 0.5, 1]
        ],
        tags: [:route],
        unit: {:native, :second}
      ),
      # Absinthe operations
      distribution([:absinthe, :execute, :operation, :stop, :duration],
        reporter_options: [
          buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10]
        ],
        tag_values: &expose_absinthe_op_name/1,
        tags: [:operation_name],
        unit: {:native, :second}
      ),

      # Database Metrics

      distribution("siwapp.repo.query.idle_time",
        reporter_options: [
          buckets: [0.01, 0.02, 0.03, 0.05, 0.1, 0.5, 1, 5]
        ],
        tags: [:type, :source],
        unit: {:native, :second}
      ),
      distribution("siwapp.repo.query.queue_time",
        reporter_options: [
          buckets: [0.01, 0.02, 0.03, 0.05, 0.1, 0.5, 1, 5]
        ],
        tags: [:type, :source],
        unit: {:native, :second}
      ),
      distribution("siwapp.repo.query.query_time",
        reporter_options: [
          buckets: [0.01, 0.02, 0.03, 0.05, 0.1, 0.5, 1, 5]
        ],
        tags: [:type, :source],
        unit: {:native, :second}
      ),
      distribution("siwapp.repo.query.total_time",
        reporter_options: [
          buckets: [0.01, 0.02, 0.03, 0.05, 0.1, 0.5, 1, 5]
        ],
        tags: [:type, :source],
        unit: {:native, :second}
      ),
      distribution("siwapp.repo.query.decode_time",
        reporter_options: [
          buckets: [0.01, 0.02, 0.03, 0.05, 0.1, 0.5, 1, 5]
        ],
        tags: [:type, :source],
        unit: {:native, :second}
      )
    ]
  end

  @spec periodic_measurements :: list
  def periodic_measurements do
    [
      {__MODULE__, :cpu_usage, []},
      {__MODULE__, :process_limit, []}
    ]
  end

  @compile {:no_warn_undefined, :cpu_sup}
  @spec cpu_usage :: :ok
  def cpu_usage do
    :telemetry.execute([:vm, :cpu], %{usage: :cpu_sup.util()}, %{})
  end

  @spec process_limit :: :ok
  def process_limit do
    :telemetry.execute(
      [:vm, :system_limits],
      %{process: :erlang.system_info(:process_limit)},
      %{}
    )
  end

  @spec expose_absinthe_op_name(map) :: map
  defp expose_absinthe_op_name(
         %{
           blueprint: %{
             input: %{definitions: [%{selection_set: %{selections: [%{name: name} | _]}} | _]}
           }
         } = metadata
       ) do
    Map.put(metadata, :operation_name, name)
  end
end

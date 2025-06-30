defmodule Siwapp.Telemetry.Plugin.Phoenix do
  @moduledoc false

  use PromEx.Plugin

  def event_metrics(_opts) do
    [
      distribution_metrics()
    ]
  end

  @spec distribution_metrics :: any
  defp distribution_metrics do
    metrics = [
      counter("phoenix.endpoint.count",
        event_name: [:phoenix, :endpoint, :stop],
        measurement: :duration,
        tag_values: fn %{conn: conn} -> %{status: conn.status} end,
        tags: [:status]
      ),
      distribution("phoenix.live_view.mount.stop.duration",
        event_name: [:phoenix, :live_view, :mount, :stop],
        reporter_options: [
          buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10]
        ],
        unit: {:native, :second}
      ),
      distribution("phoenix.endpoint.stop.duration",
        reporter_options: [
          buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10]
        ],
        unit: {:native, :second}
      ),
      distribution("phoenix.router_dispatch.stop.duration",
        reporter_options: [
          buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10]
        ],
        tags: [:route],
        unit: {:native, :second}
      )
    ]

    Event.build(:siwapp_distribution_metrics, metrics)
  end
end

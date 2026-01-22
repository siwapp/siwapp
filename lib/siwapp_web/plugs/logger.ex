defmodule SiwappWeb.Plugs.Logger do
  @moduledoc """
  Plug to log requests made to Siwapp, for debug purposes.
  """
  @behaviour Plug

  require Logger

  alias Plug.Conn

  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts) do
    opts
  end

  @spec call(Conn.t(), Plug.opts()) :: Conn.t()
  def call(%{request_path: "/status"} = conn, _opts), do: conn

  def call(conn, _opts) do
    start = System.monotonic_time(:microsecond)
    conn = Conn.assign(conn, :start, start)

    Conn.register_before_send(conn, fn conn ->
      stop = System.monotonic_time(:microsecond)
      diff = stop - start

      # Log to console
      Logger.info(fn ->
        [
          conn.method,
          ?\s,
          conn.request_path,
          ?\s,
          # params,
          # ?\s,
          Integer.to_string(conn.status),
          ?\s,
          body_length(conn.resp_body),
          ?\s,
          formatted_diff(diff),
          ?\s,
          get_remote_ip(conn)
        ]
      end)

      conn
    end)
  end

  @spec body_length(list() | nil | binary()) :: binary()
  defp body_length(body) when is_list(body),
    do: body |> Enum.join("") |> String.length() |> Integer.to_string()

  defp body_length(nil), do: "0"
  defp body_length(body), do: body |> String.length() |> Integer.to_string()

  @spec get_remote_ip(Conn.t()) :: binary()
  defp get_remote_ip(conn), do: to_string(:inet_parse.ntoa(conn.remote_ip))

  @spec formatted_diff(integer()) :: [binary(), ...]
  defp formatted_diff(diff) when diff > 1000,
    do: [diff |> div(1000) |> Integer.to_string(), "ms"]

  defp formatted_diff(diff), do: [Integer.to_string(diff), "µs"]
end

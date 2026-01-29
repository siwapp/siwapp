defmodule SiwappWeb.Plugs.Logger do
  @moduledoc """
  Plug to log requests made to Siwapp, for debug purposes.
  """
  @behaviour Plug

  import Plug.Conn, only: [get_req_header: 2]

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

  @spec get_remote_ip(Conn.t()) :: String.t()
  defp get_remote_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [] ->
        conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

      [forwarded] ->
        forwarded |> String.split(",") |> Enum.at(-1) |> String.trim()
    end
  end

  @spec body_length(list() | nil | binary()) :: binary()
  defp body_length(body) when is_list(body),
    do: body |> Enum.join("") |> body_length()

  defp body_length(nil), do: "0"
  defp body_length(body), do: body |> byte_size() |> Integer.to_string()

  @spec formatted_diff(integer()) :: [binary(), ...]
  defp formatted_diff(diff) when diff > 1000,
    do: [diff |> div(1000) |> Integer.to_string(), "ms"]

  defp formatted_diff(diff), do: [Integer.to_string(diff), "µs"]
end

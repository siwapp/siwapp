defmodule SiwappWeb.Utils do
  @moduledoc """
  Module for utility functions.
  """

  import Plug.Conn, only: [get_req_header: 2]

  alias Plug.Conn

  @doc """
  Check the X-Forwarded-For header to identify the origin of a client IP address
  connected to a web server via an HTTP proxy or load balancer.
  If the header does not exist, get the remote ip of the conn
  """
  @spec get_remote_ip(Conn.t()) :: String.t()
  def get_remote_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [] ->
        conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

      [forwarded] ->
        # if it's a list get the last item
        forwarded |> String.split(",") |> Enum.at(-1) |> String.trim()
    end
  end
end

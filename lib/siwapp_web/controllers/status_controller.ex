defmodule SiwappWeb.StatusController do
  use SiwappWeb, :controller

  alias Ecto.Adapters.SQL
  alias Plug.Conn

  @doc """
  Just for load balancer checks
  """
  @spec status(Conn.t(), map) :: Conn.t()
  def status(conn, _params) do
    Siwapp.Repo
    |> SQL.query("SELECT 1")
    |> process_status(conn)
  end

  @spec process_status(any, any) :: any
  defp process_status({:ok, _}, conn), do: text(conn, "OK")

  defp process_status(err, conn) do
    conn
    |> put_status(500)
    |> text(inspect(err))
  end
end

defmodule SiwappWeb.Api.InvoicesController do
  use SiwappWeb, :controller

  @spec download(Plug.Conn.t(), map) :: Plug.Conn.t()
  def download(conn, params) do
    SiwappWeb.PageController.download(conn, params)
  end
end

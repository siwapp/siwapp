defmodule SiwappWeb.IframeController do
  use SiwappWeb, :controller
  alias Siwapp.Invoices
  alias Siwapp.Templates

  plug :put_root_layout, false
  plug :put_layout, false

  @spec iframe(Plug.Conn.t(), map) :: Plug.Conn.t()
  def iframe(conn, %{"id" => id}) do
    invoice = Invoices.get!(id, preload: [{:items, :taxes}, :payments, :series])
    str_template = Templates.print_str_template(invoice)

    html(conn, str_template)
  end
end

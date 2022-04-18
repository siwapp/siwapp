defmodule SiwappWeb.LayoutView do
  use SiwappWeb, :view

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def shared_button(%Phoenix.LiveView.Socket{} = socket) do
    case socket.view do
      n when n in [SiwappWeb.SeriesLive.Index, SiwappWeb.SeriesLive.FormComponent] ->
        new_button("New Series", Routes.series_index_path(socket, :new))

      n when n in [SiwappWeb.CustomersLive.Index, SiwappWeb.CustomersLive.Edit] ->
        new_button("New Customer", Routes.customers_edit_path(socket, :new))

      n when n in [SiwappWeb.TaxesLive.Index, SiwappWeb.TaxesLive.FormComponent] ->
        new_button("New Tax", Routes.taxes_index_path(socket, :new))

      n when n in [SiwappWeb.TemplatesLive.Index, SiwappWeb.TemplatesLive.Edit] ->
        new_button("New Template", Routes.templates_edit_path(socket, :new))

      n when n in [SiwappWeb.RecurringInvoicesLive.Index, SiwappWeb.RecurringInvoicesLive.Edit] ->
        new_button("New Recurring Invoice", Routes.recurring_invoices_edit_path(socket, :new))

      n when n in [SiwappWeb.UsersLive.Index] ->
        new_button("New User", Routes.users_index_path(socket, :new))

      _ ->
        new_button("New Invoice", Routes.invoices_edit_path(socket, :new))
    end
  end

  @spec shared_button(Plug.Conn.t()) :: any()
  def shared_button(%Plug.Conn{} = conn) do
    new_button("New Invoice", Routes.invoices_edit_path(conn, :new))
  end

  def render_search_live(%Phoenix.LiveView.Socket{} = socket) do
    views_with_search = [
      SiwappWeb.InvoicesLive.Index,
      SiwappWeb.CustomersLive.Index,
      SiwappWeb.RecurringInvoicesLive.Index
    ]

    if socket.view in views_with_search do
      view = which_view(socket.view)
      live_component(SiwappWeb.SearchLive.SearchComponent, id: "search", view: view)
    end
  end

  @spec render_search_live(Plug.Conn.t()) :: nil
  def render_search_live(%Plug.Conn{}) do
    nil
  end

  @spec new_button(binary, binary) :: any()
  defp new_button(text, to) do
    live_redirect(text, to: to, method: :get, class: "button is-info")
  end

  @spec which_view(atom()) :: binary()
  def which_view(view) do
    case view do
      SiwappWeb.InvoicesLive.Index ->
        "invoice"

      SiwappWeb.CustomersLive.Index ->
        "customer"

      SiwappWeb.RecurringInvoicesLive.Index ->
        "recurring_invoice"
    end
  end
end

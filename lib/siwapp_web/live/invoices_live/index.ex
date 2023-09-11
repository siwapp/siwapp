defmodule SiwappWeb.InvoicesLive.Index do
  @moduledoc false
  use SiwappWeb, :live_view
  alias Siwapp.Invoices
  alias Siwapp.Invoices.Invoice
  alias Siwapp.Searches
  alias SiwappWeb.Component.Sortener

  @invoices_limit 20
  @order_by_default [desc: :id]

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    query = Searches.filters_query(Invoice, params)

    send_update(SiwappWeb.SearchLive.SearchComponent,
      id: "search",
      view: "invoice",
      params: params
    )

    page_title =
      if Map.has_key?(params, "customer_id") do
        "Invoices for #{Siwapp.Customers.get!(params["customer_id"]).name}"
      else
        "Invoices"
      end

    {:ok,
     socket
     |> assign(:page, 0)
     |> assign(:no_more_queries, 0)
     |> assign(
       :invoices,
       Searches.filters(query, limit: @invoices_limit, preload: [:series], deleted_at_query: true)
     )
     |> assign(:checked, MapSet.new())
     |> assign(:query, query)
     |> assign(:sort_map, %Sortener{})
     |> assign(:order_by, @order_by_default)
     |> assign(:page_title, page_title)}
  end

  @impl Phoenix.LiveView
  def handle_event("load-more", _, socket) do
    %{
      page: page,
      invoices: invoices,
      query: query,
      order_by: order_by
    } = socket.assigns

    next_invoices =
      Searches.filters(query,
        limit: @invoices_limit,
        offset: (page + 1) * @invoices_limit,
        preload: [:series],
        deleted_at_query: true,
        order_by: order_by
      )

    {invoices, no_more_queries} = maybe_add(invoices, next_invoices)

    {
      :noreply,
      assign(socket,
        invoices: invoices,
        page: page + 1,
        no_more_queries: no_more_queries
      )
    }
  end

  def handle_event("click_checkbox", params, socket) do
    checked = update_checked(params, socket)

    {:noreply, assign(socket, checked: checked)}
  end

  def handle_event("redirect", %{"id" => id}, socket) do
    invoice = Invoices.get!(id)

    if Invoices.status(invoice) == :paid do
      {:noreply, push_redirect(socket, to: Routes.page_path(socket, :show_invoice, id))}
    else
      {:noreply, push_redirect(socket, to: Routes.invoices_edit_path(socket, :edit, id))}
    end
  end

  def handle_event("delete", _params, socket) do
    socket.assigns.checked
    |> MapSet.to_list()
    |> Enum.reject(&(&1 == 0))
    |> Enum.map(&Invoices.get!(&1, preload: [{:items, :taxes}, :payments]))
    |> Enum.each(&Invoices.delete(&1))

    socket =
      socket
      |> put_flash(:info, "Invoices succesfully deleted")
      |> assign(:checked, MapSet.new())
      |> assign(
        :invoices,
        Searches.filters(socket.assigns.query,
          limit: @invoices_limit,
          preload: [:series],
          deleted_at_query: true
        )
      )

    {:noreply, socket}
  end

  def handle_event("send_email", _params, socket) do
    socket.assigns.checked
    |> MapSet.to_list()
    |> Enum.reject(&(&1 == 0))
    |> Enum.map(&Invoices.get!(&1, preload: [{:items, :taxes}, :series, :payments]))
    |> Enum.each(&Invoices.send_email(&1))

    socket =
      socket
      |> put_flash(:info, "Invoices sent by mail")
      |> push_redirect(to: Routes.invoices_index_path(socket, :index))

    {:noreply, socket}
  end

  def handle_event("set_paid", _params, socket) do
    socket.assigns.checked
    |> MapSet.to_list()
    |> List.delete(0)
    |> Enum.map(&Invoices.get!(&1, preload: [{:items, :taxes}, :payments]))
    |> Enum.filter(&(!&1.paid))
    |> Enum.each(&Invoices.set_paid(&1))

    socket =
      socket
      |> put_flash(:info, "Invoices succesfully paid")
      |> assign(:checked, MapSet.new())
      |> assign(
        :invoices,
        Searches.filters(socket.assigns.query,
          limit: @invoices_limit,
          preload: [:series],
          deleted_at_query: true
        )
      )

    {:noreply, socket}
  end

  def handle_event("reorder", %{"field" => field, "order" => order}, socket) do
    order_by =
      order
      |> String.to_atom()
      |> Searches.prepare_order_by(String.to_atom(field))

    socket =
      socket
      |> assign(:order_by, order_by)
      |> assign(:sort_map, %Sortener{order: order, field: field})
      |> assign(
        :invoices,
        Searches.filters(socket.assigns.query,
          limit: @invoices_limit,
          preload: [:series],
          deleted_at_query: true,
          order_by: order_by
        )
      )

    {:noreply, socket}
  end

  def handle_event("reorder", _params, socket),
    do: handle_event("reorder", %{"field" => "id", "order" => "desc"}, socket)

  @impl Phoenix.LiveView
  def handle_info({:search, params}, socket) do
    {:noreply, push_redirect(socket, to: Routes.invoices_index_path(socket, :index, params))}
  end

  @spec download_url(MapSet.t()) :: binary
  def download_url(checked) do
    "invoices/download" <>
      (checked
       |> MapSet.to_list()
       |> Enum.reject(&(&1 == 0))
       |> Enum.reduce("", fn id, acc -> acc <> "/#{id}" end))
  end

  @spec update_checked(map(), Phoenix.LiveView.Socket.t()) :: MapSet.t()
  defp update_checked(%{"id" => "0", "value" => "on"}, socket) do
    socket.assigns.invoices
    |> MapSet.new(& &1.id)
    |> MapSet.put(0)
  end

  defp update_checked(%{"id" => "0"}, _) do
    MapSet.new()
  end

  defp update_checked(%{"id" => id, "value" => "on"}, socket) do
    MapSet.put(socket.assigns.checked, String.to_integer(id))
  end

  defp update_checked(%{"id" => id}, socket) do
    socket.assigns.checked
    |> MapSet.delete(String.to_integer(id))
    |> MapSet.delete(0)
  end
end

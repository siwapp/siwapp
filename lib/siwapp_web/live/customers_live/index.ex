defmodule SiwappWeb.CustomersLive.Index do
  @moduledoc false

  use SiwappWeb, :live_view

  import SiwappWeb.PageView

  alias Siwapp.Customers
  alias Siwapp.Customers.Customer
  alias Siwapp.Searches

  @customers_limit 20

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    query = Searches.filters_query(Customer, params)

    send_update(SiwappWeb.SearchLive.SearchComponent,
      id: "search",
      view: "customer",
      params: params
    )

    {:ok,
     socket
     |> assign(:page, 0)
     |> assign(:no_more_queries, 0)
     |> assign(:query, query)
     |> assign(customers: Customers.list_with_assoc_invoice_fields(query, @customers_limit))
     |> assign(page_title: "Customers")}
  end

  @impl Phoenix.LiveView
  def handle_event("load-more", _, socket) do
    %{
      page: page,
      customers: customers,
      query: query
    } = socket.assigns

    next_customers =
      Customers.list_with_assoc_invoice_fields(
        query,
        @customers_limit,
        (page + 1) * @customers_limit
      )

    {customers, no_more_queries} = maybe_add(customers, next_customers)

    {
      :noreply,
      assign(socket,
        customers: customers,
        page: page + 1,
        no_more_queries: no_more_queries
      )
    }
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, push_redirect(socket, to: Routes.customers_edit_path(socket, :edit, id))}
  end

  @impl Phoenix.LiveView
  def handle_info({:search, params}, socket) do
    {:noreply, push_redirect(socket, to: Routes.customers_index_path(socket, :index, params))}
  end

  @spec due(integer, integer) :: integer
  defp due(total, paid), do: total - paid

  @spec set_currency([] | [String.t()]) :: binary
  defp set_currency([]), do: "USD"
  defp set_currency(currencies), do: List.first(currencies)

  @spec symbol_option([] | [String.t()]) :: [{:symbol, true}] | [{:symbol, false}]
  defp symbol_option([_currency]), do: [{:symbol, true}]
  defp symbol_option(_currencies), do: [{:symbol, false}]
end

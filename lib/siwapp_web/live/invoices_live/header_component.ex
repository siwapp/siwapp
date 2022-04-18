defmodule SiwappWeb.InvoicesLive.HeaderComponent do
  @moduledoc false
  use SiwappWeb, :live_component

  import SiwappWeb.PageView, only: [money_format: 2, money_format: 3]

  alias Siwapp.Invoices.Statistics
  alias SiwappWeb.GraphicHelpers

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign(summary_state: set_summary(:closed))
     |> assign(default_currency: Siwapp.Settings.value(:currency))}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {gross_totals, count} = Statistics.get_amount_per_currencies_and_count(assigns.query, :gross)
    default_total = gross_totals[socket.assigns.default_currency] || 0
    others_totals = Map.drop(gross_totals, [socket.assigns.default_currency])

    {:ok,
     socket
     |> assign(page_title: assigns.page_title)
     |> assign(count: count)
     |> assign(default_total: default_total)
     |> assign(other_totals: others_totals)
     |> assign(gross_totals: gross_totals)
     |> assign(query: assigns.query)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="mb-4">
      <div class="is-flex is-justify-content-space-between ">
        <div class="is-flex is-align-items-end">
          <h1 class="mb-2">
            <%= @page_title %>
            <span class="subtitle is-5">
              <%= "(#{@count} Found)" %>
            </span>
          </h1>
        </div>
        <header
          class="card card-header is-clickable is-unselectable is-size-5"
          phx-click="change-summary-state"
          phx-target={@myself}
        >
          <div class="card-header-content m-3 is-flex is-flex-wrap-wrap is-justify-content-space-around is-two-fifths">
            <%= for {currency, total} <- @other_totals do %>
              <span class="has-text-weight-medium p-2">
                <%= money_format(total, currency) %>
              </span>
            <% end %>
            <span class="has-text-weight-bold p-2">
              <%= money_format(@default_total, @default_currency) %>
            </span>
          </div>
          <button class="card-header-icon pl-0" aria-label="more options">
            <span class="icon">
              <i class={"fas #{@summary_state.icon}"} aria-hidden="true"></i>
            </span>
          </button>
        </header>
      </div>

      <div id="summary-card" class={"card #{@summary_state.visibility}"}>
        <%= if @summary_state.visibility == "is-block" do %>
          <div class="card-content">
            <div class="content">
              <%= summary_chart(@chart_data) %>
            </div>
            <%= render(SiwappWeb.PageView, "totals_info.html",
              gross_totals: @gross_totals,
              net_totals: @net_totals,
              taxes: @taxes
            ) %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("change-summary-state", _params, socket) do
    if socket.assigns.summary_state.visibility == "is-hidden" do
      {net_totals, _} = Statistics.get_amount_per_currencies_and_count(socket.assigns.query, :net)
      taxes = Statistics.get_tax_amount_per_currencies(socket.assigns.query)

      {:noreply,
       socket
       |> assign(:summary_state, set_summary(:opened))
       |> assign(net_totals: net_totals)
       |> assign(chart_data: Statistics.get_amount_per_day(socket.assigns.query))
       |> assign(taxes: taxes)}
    else
      {:noreply, assign(socket, :summary_state, set_summary(:closed))}
    end
  end

  @spec summary_chart([tuple]) :: {:safe, [...]}
  defp summary_chart(invoices_data) do
    invoices_data
    |> Enum.map(fn {date, amount} -> {NaiveDateTime.new!(date, ~T[00:00:00]), amount} end)
    |> GraphicHelpers.line_plot(
      y_formatter: &money_format(round(&1), "USD", symbol: false, fractional_unit: false)
    )
  end

  @spec set_summary(:opened | :closed) :: map()
  defp set_summary(:opened), do: %{visibility: "is-block", icon: "fa-angle-up"}
  defp set_summary(:closed), do: %{visibility: "is-hidden", icon: "fa-angle-down"}
end

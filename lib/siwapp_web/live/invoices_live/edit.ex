defmodule SiwappWeb.InvoicesLive.Edit do
  @moduledoc false
  use SiwappWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Phoenix.LiveView.Socket
  alias Siwapp.Commons
  alias Siwapp.Commons.Series
  alias Siwapp.Invoices
  alias Siwapp.Invoices.Invoice

  @typep series_options :: list(keyword(key: String.t(), value: String.t(), selected: String.t()))

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    series = Commons.list_series()

    {:ok,
     socket
     |> assign(:series, series)
     |> assign(:series_options, set_series_options(series))
     |> assign(:url_query_string, Map.delete(params, "id"))
     |> assign(:currency_options, Invoices.list_currencies())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"invoice" => params}, socket) do
    result =
      case socket.assigns.live_action do
        :new -> Invoices.create(params)
        :edit -> Invoices.update(socket.assigns.invoice, params)
      end

    case result do
      {:ok, _invoice} ->
        socket =
          socket
          |> put_flash(:info, "Invoice successfully saved")
          |> push_redirect(
            to: Routes.invoices_index_path(socket, :index, socket.assigns.url_query_string)
          )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate", %{"invoice" => params}, socket) do
    changeset = Invoices.change(socket.assigns.invoice, params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("delete", _params, socket) do
    Invoices.delete(socket.assigns.invoice)

    socket =
      socket
      |> put_flash(:info, "Invoice succesfully deleted")
      |> push_redirect(to: Routes.invoices_index_path(socket, :index))

    {:noreply, socket}
  end

  def handle_event("copy", _params, socket) do
    invoicing_address = Ecto.Changeset.get_field(socket.assigns.changeset, :invoicing_address)

    {:noreply,
     update(
       socket,
       :changeset,
       &Ecto.Changeset.put_change(&1, :shipping_address, invoicing_address)
     )}
  end

  def handle_event("send_email", %{"id" => id}, socket) do
    invoice = Invoices.get!(id, preload: [{:items, :taxes}, :series, :payments])

    socket =
      case Invoices.send_email(invoice) do
        {:ok, _} ->
          put_flash(socket, :info, "Invoice sent by email")

        {:error, msg} ->
          put_flash(socket, :error, msg)
      end

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:params_updated, params}, socket) do
    changeset = Invoices.change(socket.assigns.invoice, params)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t(), :new | :edit, map()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :new, %{"id" => id}) do
    invoice = Invoices.get!(id, preload: [{:items, :taxes}, :payments, :series, :customer])

    socket
    |> assign(:action, :new)
    |> assign(:page_title, "New Invoice")
    |> assign(:invoice, %Invoice{})
    |> then(&assign(&1, :series_options, set_series_options(&1, invoice)))
    |> assign(:changeset, Invoices.duplicate(invoice))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:action, :new)
    |> assign(:page_title, "New Invoice")
    |> assign(:invoice, %Invoice{})
    |> assign(:changeset, Invoices.change(%Invoice{}, %{}))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    invoice = Invoices.get!(id, preload: [{:items, :taxes}, :payments, :series, :customer])

    socket
    |> assign(:action, :edit)
    |> assign(:page_title, "#{invoice.series.code}-#{Map.get(invoice, :number)}")
    |> assign(:invoice, invoice)
    |> then(&assign(&1, :series_options, set_series_options(&1, invoice)))
    |> assign(:changeset, Invoices.change(invoice))
  end

  @spec set_series_options(series :: list(Series.t())) :: series_options
  defp set_series_options(series) do
    Enum.map(series, &[key: &1.name, value: &1.id, selected: &1.default])
  end

  @spec set_series_options(socket :: Socket.t(), invoice :: Invoice.t()) :: series_options
  defp set_series_options(socket, invoice) do
    selected_series = invoice.series.id

    Enum.map(
      socket.assigns.series,
      &[key: &1.name, value: &1.id, selected: &1.id == selected_series]
    )
  end
end

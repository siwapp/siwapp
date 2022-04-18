defmodule SiwappWeb.InvoicesLive.Edit do
  @moduledoc false
  use SiwappWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Siwapp.Commons
  alias Siwapp.Invoices
  alias Siwapp.Invoices.Invoice

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:series, Commons.list_series())
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
        :edit -> Invoices.update(socket.assigns.invoice, put_assoc_if_empty(params))
      end

    case result do
      {:ok, _invoice} ->
        socket =
          socket
          |> put_flash(:info, "Invoice successfully saved")
          |> push_redirect(to: Routes.invoices_index_path(socket, :index))

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

  def handle_event("add_payment", %{"params" => params}, socket) do
    currency = Ecto.Changeset.get_field(socket.assigns.changeset, :currency)
    gross_amount = Ecto.Changeset.get_field(socket.assigns.changeset, :gross_amount)
    paid_amount = Ecto.Changeset.get_field(socket.assigns.changeset, :paid_amount)

    virtual_left_amount =
      (gross_amount - paid_amount)
      |> Money.new(currency)
      |> Money.to_decimal()

    params =
      if params["payments"] == nil do
        Map.put(params, "payments", %{"0" => new_payment_params(virtual_left_amount)})
      else
        next_payment_index =
          params["payments"]
          |> Enum.count()
          |> Integer.to_string()

        put_in(params, ["payments", next_payment_index], new_payment_params(virtual_left_amount))
      end

    {:noreply, assign(socket, changeset: Invoices.change(socket.assigns.invoice, params))}
  end

  def handle_event("remove_payment", %{"payment_id" => payment_index, "params" => params}, socket) do
    params =
      params
      |> pop_in(["payments", Integer.to_string(payment_index)])
      |> elem(1)
      |> Map.update!("payments", &sort_indexes/1)

    {:noreply, assign(socket, changeset: Invoices.change(socket.assigns.invoice, params))}
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

  @spec sort_indexes(map) :: map
  def sort_indexes(elements) do
    values = Map.values(elements)
    indexes = 0..(length(values) - 1)

    indexes
    |> Enum.zip(values)
    |> Enum.map(fn {k, v} -> {Integer.to_string(k), v} end)
    |> Map.new()
  end

  @spec apply_action(Phoenix.LiveView.Socket.t(), :new | :edit, map()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :new, %{"id" => id}) do
    socket
    |> assign(:action, :new)
    |> assign(:page_title, "New Invoice")
    |> assign(:invoice, %Invoice{})
    |> assign(
      :changeset,
      Invoices.duplicate(
        Invoices.get!(id, preload: [{:items, :taxes}, :payments, :series, :customer])
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:action, :new)
    |> assign(:page_title, "New Invoice")
    |> assign(:invoice, %Invoice{})
    |> assign(
      :changeset,
      Invoices.change(%Invoice{}, %{
        "items" => %{"0" => %{"taxes" => Commons.default_taxes_names()}}
      })
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    invoice = Invoices.get!(id, preload: [{:items, :taxes}, :payments, :series, :customer])

    socket
    |> assign(:action, :edit)
    |> assign(:page_title, invoice.series.code <> "-" <> Integer.to_string(invoice.number))
    |> assign(:invoice, invoice)
    |> assign(
      :changeset,
      Invoices.change(invoice, %{
        "items" => items_as_params(invoice.items),
        "payments" => payments_as_params(invoice.payments)
      })
    )
  end

  @spec put_assoc_if_empty(map()) :: map()
  defp put_assoc_if_empty(params) do
    params
    |> then(&if Map.has_key?(&1, "items"), do: &1, else: Map.put(&1, "items", []))
    |> then(&if Map.has_key?(&1, "payments"), do: &1, else: Map.put(&1, "payments", []))
  end

  @spec items_as_params([Siwapp.Invoices.Item.t()]) :: map()
  defp items_as_params(items) do
    items
    |> Enum.map(fn item ->
      item
      |> Map.take([:description, :discount, :quantity, :id])
      |> Mappable.to_map(keys: :strings)
      |> Map.put("taxes", Enum.map(item.taxes, & &1.name))
      |> Map.put("virtual_unitary_cost", item.virtual_unitary_cost)
    end)
    |> Enum.with_index()
    |> Enum.map(fn {item, i} -> {Integer.to_string(i), item} end)
    |> Map.new()
  end

  @spec payments_as_params([Siwapp.Invoices.Payment.t()]) :: map
  defp payments_as_params(payments) do
    payments
    |> Enum.map(&Map.take(Map.from_struct(&1), [:amount, :date, :notes, :id]))
    |> Enum.with_index()
    |> Enum.map(fn {payment, i} -> {Integer.to_string(i), payment} end)
    |> Map.new()
  end

  @spec new_payment_params(Decimal.t()) :: map
  defp new_payment_params(virtual_amount) do
    %{
      "date" => Date.utc_today(),
      "notes" => "",
      "virtual_amount" => virtual_amount
    }
  end
end

defmodule SiwappWeb.RecurringInvoicesLive.Edit do
  @moduledoc false
  use SiwappWeb, :live_view

  alias Phoenix.HTML.FormData

  alias Siwapp.Commons
  alias Siwapp.Invoices
  alias Siwapp.RecurringInvoices
  alias Siwapp.RecurringInvoices.RecurringInvoice

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
  def handle_event("save", %{"recurring_invoice" => params}, socket) do
    result =
      case socket.assigns.live_action do
        :new ->
          RecurringInvoices.create(params)

        :edit ->
          RecurringInvoices.update(socket.assigns.recurring_invoice, put_items_if_empty(params))
      end

    case result do
      {:ok, _recurring_invoice} ->
        socket =
          socket
          |> put_flash(:info, "Recurring Invoice successfully saved")
          |> push_redirect(to: Routes.recurring_invoices_index_path(socket, :index))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate", %{"recurring_invoice" => params}, socket) do
    changeset = RecurringInvoices.change(socket.assigns.recurring_invoice, params)

    {:noreply, assign(socket, :changeset, changeset)}
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

  def handle_event("delete", _params, socket) do
    RecurringInvoices.delete(socket.assigns.recurring_invoice)

    socket =
      socket
      |> put_flash(:info, "Recurring Invoice succesfully deleted")
      |> push_redirect(to: Routes.recurring_invoices_index_path(socket, :index))

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:params_updated, params}, socket) do
    changeset = RecurringInvoices.change(socket.assigns.recurring_invoice, params)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t(), :new | :edit, map()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:action, :new)
    |> assign(:page_title, "New Recurring Invoice")
    |> assign(:recurring_invoice, %RecurringInvoice{})
    |> assign(
      :changeset,
      RecurringInvoices.change(%RecurringInvoice{}, %{
        "items" => %{"0" => %{"taxes" => Commons.default_taxes_names()}}
      })
    )
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    recurring_invoice = RecurringInvoices.get!(String.to_integer(id), :preload)

    socket
    |> assign(:action, :edit)
    |> assign(:page_title, recurring_invoice.name)
    |> assign(:recurring_invoice, recurring_invoice)
    |> assign(
      :changeset,
      RecurringInvoices.change(recurring_invoice, %{"items" => recurring_invoice.items})
    )
  end

  @spec put_items_if_empty(map()) :: map()
  defp put_items_if_empty(params) do
    if Map.has_key?(params, "items"), do: params, else: Map.put(params, "items", %{})
  end

  # Replicates inputs_for behavior for recurring_invoice's items even when there's no association
  # using items_transformed, which are the changed items
  @spec pseudo_inputs_for(Ecto.Changeset.t()) :: [FormData.t()]
  defp pseudo_inputs_for(changeset) do
    items_changesets = Ecto.Changeset.get_field(changeset, :items)

    Enum.map(Enum.with_index(items_changesets), fn {item_changeset, i} ->
      indexed_item_form(item_changeset, i)
    end)
  end

  @spec indexed_item_form(Ecto.Changeset.t(), non_neg_integer()) :: FormData.t()
  defp indexed_item_form(item_changeset, index) do
    fi = FormData.to_form(item_changeset, [])

    %{
      fi
      | id: "recurring_invoice_items_#{index}",
        name: "recurring_invoice[items][#{index}]",
        index: index,
        options: [],
        errors: fi.source.errors
    }
  end
end

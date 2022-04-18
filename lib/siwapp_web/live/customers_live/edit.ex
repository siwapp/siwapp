defmodule SiwappWeb.CustomersLive.Edit do
  @moduledoc false
  use SiwappWeb, :live_view

  alias Siwapp.Customers
  alias Siwapp.Customers.Customer

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"customer" => params}, socket) do
    changeset = Customers.change(socket.assigns.customer, params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"customer" => params}, socket) do
    result =
      case socket.assigns.live_action do
        :new -> Customers.create(params)
        :edit -> Customers.update(socket.assigns.customer, params)
      end

    case result do
      {:ok, _customer} ->
        socket =
          socket
          |> put_flash(:info, "Customer successfully saved")
          |> push_redirect(to: Routes.customers_index_path(socket, :index))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("delete", _params, socket) do
    {:noreply,
     socket.assigns.customer
     |> Customers.delete()
     |> case do
       {:ok, _} ->
         put_flash(socket, :info, "Customer succesfully deleted")

       {:error, msg} ->
         put_flash(socket, :error, msg)
     end
     |> push_redirect(to: Routes.customers_index_path(socket, :index))}
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

  @spec apply_action(Phoenix.LiveView.Socket.t(), :new | :edit, map()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Customer")
    |> assign(:customer, %Customer{})
    |> assign(:changeset, Customers.change(%Customer{}))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    customer = Customers.get!(String.to_integer(id))

    socket
    |> assign(:page_title, customer.name)
    |> assign(:customer, customer)
    |> assign(:changeset, Customers.change(customer))
  end
end

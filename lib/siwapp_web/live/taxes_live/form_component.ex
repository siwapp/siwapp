defmodule SiwappWeb.TaxesLive.FormComponent do
  @moduledoc false

  use SiwappWeb, :live_component

  alias Siwapp.Commons

  @impl Phoenix.LiveComponent
  def update(%{tax: tax} = assigns, socket) do
    changeset = Commons.change_tax(tax)

    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"tax" => tax_params}, socket) do
    changeset =
      socket.assigns.tax
      |> Commons.change_tax(tax_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"tax" => tax_params}, socket) do
    Cachex.clear(:siwapp_cache)
    save_tax(socket, socket.assigns.action, tax_params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    Cachex.clear(:siwapp_cache)
    tax = Commons.get_tax!(id)

    case Commons.delete_tax(tax) do
      {:ok, _taxes} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tax was successfully destroyed.")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  @spec save_tax(Phoenix.LiveView.Socket.t(), :new | :edit, map()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  defp save_tax(socket, :edit, tax_params) do
    case Commons.update_tax(socket.assigns.tax, tax_params) do
      {:ok, _tax} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tax was successfully updated")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_tax(socket, :new, tax_params) do
    case Commons.create_tax(tax_params) do
      {:ok, _tax} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tax was successfully created")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

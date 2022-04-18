defmodule SiwappWeb.TaxesLive.Index do
  @moduledoc false

  use SiwappWeb, :live_view

  alias Siwapp.Commons
  alias Siwapp.Commons.Tax

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    taxes = Commons.list_taxes()
    {:ok, assign(socket, taxes: taxes)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("defaultClicked", %{"id" => id}, socket) do
    Cachex.clear(:siwapp_cache)
    Commons.set_default_tax(id)
    taxes = Commons.list_taxes()

    {:noreply, assign(socket, taxes: taxes)}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, push_redirect(socket, to: Routes.taxes_index_path(socket, :edit, id))}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t(), :new | :edit | :index, map()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :edit, %{"id" => id}) do
    tax = Commons.get_tax!(id)

    socket
    |> assign(:page_title, tax.name)
    |> assign(:tax, tax)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tax")
    |> assign(:tax, %Tax{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Taxes")
    |> assign(:tax, nil)
  end
end

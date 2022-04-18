defmodule SiwappWeb.SearchLive.SearchComponent do
  @moduledoc false
  use SiwappWeb, :live_component
  alias Phoenix.LiveView.JS
  alias Siwapp.Commons
  alias Siwapp.Searches
  alias Siwapp.Searches.Search

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, series_names: Commons.list_series_names())}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign_changeset(assigns)
      |> assign(view: assigns.view)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("change", %{"search" => search_params}, socket) do
    changeset = Searches.change(%Search{}, search_params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("search", %{"search" => params}, socket) do
    params = Enum.reject(params, fn {_key, val} -> val in ["", "Choose..."] end)

    send(self(), {:search, params})

    {:noreply, socket}
  end

  @spec assign_changeset(Phoenix.LiveView.Socket.t(), map) ::
          Phoenix.LiveView.Socket.t()
  defp assign_changeset(%{assigns: %{changeset: changeset}} = socket, %{name: name}) do
    changes_params = Map.replace(changeset.changes, :name, name)

    changeset = Searches.change(%Search{}, changes_params)
    assign(socket, :changeset, changeset)
  end

  defp assign_changeset(socket, %{params: params}) do
    changeset = Searches.change(%Search{}, params)

    assign(socket, :changeset, changeset)
  end

  defp assign_changeset(socket, _) do
    assign(socket, :changeset, Searches.change(%Search{}))
  end
end

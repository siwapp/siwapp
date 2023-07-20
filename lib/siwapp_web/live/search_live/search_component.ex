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
    params =
      params
      |> Map.delete("csv_meta_attributes")
      |> Enum.reject(fn {_key, val} -> val in ["", "Choose..."] end)

    send(self(), {:search, params})

    {:noreply, socket}
  end

  def handle_event("add_meta_attribute", _params, socket) do
    params = socket.assigns.changeset.params
    params = Map.update(params, "csv_meta_attributes", new_ma(), fn csv_ma -> new_ma(csv_ma) end)

    changeset = Searches.change(%Search{}, params)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("remove_meta_attribute", %{"index" => index}, socket) do
    ma_params =
      socket.assigns.changeset.params
      |> Map.get("csv_meta_attributes")
      |> Map.delete(index)
      |> reindex_meta_attributes_params()

    params = Map.put(socket.assigns.changeset.params, "csv_meta_attributes", ma_params)
    changeset = Searches.change(%Search{}, params)
    {:noreply, assign(socket, :changeset, changeset)}
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

  @spec new_ma(map) :: map
  defp new_ma(ma_params \\ %{}) do
    Map.put(ma_params, "#{Enum.count(ma_params)}", %{"key" => ""})
  end

  @spec reindex_meta_attributes_params(map) :: map
  defp reindex_meta_attributes_params(ma_params) do
    Enum.reduce(ma_params, %{}, fn {_k, v}, acc -> Map.put(acc, "#{Enum.count(acc)}", v) end)
  end
end

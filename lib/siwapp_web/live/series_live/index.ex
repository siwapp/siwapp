defmodule SiwappWeb.SeriesLive.Index do
  @moduledoc false

  use SiwappWeb, :live_view

  alias Siwapp.Commons
  alias Siwapp.Commons.Series

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, series_list: Commons.list_series())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("defaultClicked", %{"id" => id}, socket) do
    series = Commons.get_series(id)
    Commons.change_default_series(series)

    {:noreply, assign(socket, series_list: Commons.list_series())}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, push_redirect(socket, to: Routes.series_index_path(socket, :edit, id))}
  end

  @spec apply_action(Phoenix.LiveView.Socket.t(), :new | :edit | :index, map()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :edit, %{"id" => id}) do
    series = Commons.get_series(id)

    socket
    |> assign(:page_title, series.name)
    |> assign(:series, series)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Series")
    |> assign(:series, %Series{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Series")
    |> assign(:series, nil)
  end
end

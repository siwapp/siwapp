defmodule SiwappWeb.TemplatesLive.Index do
  @moduledoc false
  use SiwappWeb, :live_view

  alias Siwapp.Templates

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(templates: Templates.list())
      |> assign(page_title: "Templates")

    {:ok, assign(socket, templates: Templates.list())}
  end

  @impl Phoenix.LiveView
  def handle_event("defaultClicked", %{"id" => id, "type" => type}, socket) do
    template = id |> String.to_integer() |> Templates.get()

    socket =
      case Templates.set_default(String.to_atom(type), template) do
        {:ok, _} ->
          socket
          |> assign(templates: Templates.list())
          |> clear_flash()

        {:error, %{errors: [{_key, {msg, _}}]}} ->
          put_flash(
            socket,
            :error,
            msg
          )
      end

    {:noreply, socket}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, push_redirect(socket, to: Routes.templates_edit_path(socket, :edit, id))}
  end
end

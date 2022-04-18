defmodule SiwappWeb.TemplatesLive.Edit do
  @moduledoc false

  use SiwappWeb, :live_view

  alias Siwapp.Templates
  alias Siwapp.Templates.Template

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"template" => template_params}, socket) do
    changeset =
      socket.assigns.template
      |> Templates.change(template_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"template" => template_params}, socket) do
    save_template(socket, socket.assigns.action, template_params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    template = id |> String.to_integer() |> Templates.get()

    case Templates.delete(template) do
      {:ok, _template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Template was successfully destroyed.")
         |> push_redirect(to: Routes.templates_index_path(socket, :index))}

      {:error, _msg} ->
        {:noreply, put_flash(socket, :error, "You can't delete the default template.")}
    end
  end

  @spec apply_action(Phoenix.LiveView.Socket.t(), :new | :edit, map()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :new, _params) do
    template = %Template{}

    socket
    |> assign(:action, :new)
    |> assign(:page_title, "New Template")
    |> assign(:template, template)
    |> assign(:changeset, Templates.change(template))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    template = id |> String.to_integer() |> Templates.get()

    socket
    |> assign(:action, :edit)
    |> assign(:page_title, template.name)
    |> assign(:template, template)
    |> assign(:changeset, Templates.change(template))
  end

  @spec save_template(Phoenix.LiveView.Socket.t(), :new | :edit, map()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  defp save_template(socket, :edit, template_params) do
    case Templates.update(socket.assigns.template, template_params) do
      {:ok, _template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Template was successfully updated")
         |> push_redirect(to: Routes.templates_index_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_template(socket, :new, template_params) do
    case Templates.create(template_params) do
      {:ok, _template} ->
        {:noreply,
         socket
         |> put_flash(:info, "Template was successfully created")
         |> push_redirect(to: Routes.templates_index_path(socket, :index))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

defmodule SiwappWeb.ModalComponent do
  @moduledoc false
  use SiwappWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="phx-modal"
      phx-capture-click="close"
      phx-window-keydown="close"
      phx-key="escape"
      phx-target={@myself}
      phx-page-loading
    >
      <div class="phx-modal-content">
        <.link navigate={@return_to} class="phx-modal-close">&times;</.link>
        <.live_component
          id="form"
          module={@component}
          series={@series}
          tax={@tax}
          user={@user}
          current_user_id={@current_user_id}
          title={@title}
          action={@action}
        />
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end

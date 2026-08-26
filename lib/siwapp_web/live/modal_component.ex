defmodule SiwappWeb.ModalComponent do
  @moduledoc false
  use Phoenix.Component

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="my_modal">
        hey there
      </.modal>

  It requires the parent liveview to have a "close" event handler, like this:

      def handle_event("close", _, socket) do
        {:noreply, push_patch(socket, to: Routes.series_index_path(socket, :index))}
      end

  """
  @spec modal(map) :: Phoenix.LiveView.Rendered.t()
  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      class="phx-modal"
      phx-window-keydown="close"
      phx-key="escape"
    >
      <div class="phx-modal-content" phx-click-away="close">
        <.link navigate={@return_to} class="phx-modal-close">&times;</.link>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end

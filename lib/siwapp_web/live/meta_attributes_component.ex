defmodule SiwappWeb.MetaAttributesComponent do
  @moduledoc false

  use SiwappWeb, :live_component

  alias Phoenix.HTML.Form

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    attributes =
      case Form.input_value(assigns.f, assigns.field) do
        "" -> %{}
        attrs -> attrs
      end

    socket =
      socket
      |> assign(new_key: "")
      |> assign(new_value: "")
      |> assign(attributes: attributes)
      |> assign(name: assigns.f.name)
      |> assign(field: assigns.field)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <fieldset>
      <h2>Meta Attributes</h2>
      <%= for {k, v} <- @attributes do %>
        <div class="field is-horizontal">
          <div class="field-label is-normal">
            <label class="label">
              <%= k %> :
            </label>
          </div>
          <div class="field-body">
            <input class="input field" type="text" name={"#{@name}[#{@field}][#{k}]"} value={v} />
            <span
              class="icon has-text-danger is-clickable"
              phx-click="remove"
              phx-value-key={k}
              phx-target={@myself}
            >
              <i class="fas fa-trash"></i>
            </span>
          </div>
        </div>
      <% end %>

      <%= if @attributes == %{} do %>
        <input type="hidden" name={"#{@name}[#{@field}]"} />
      <% end %>

      <div class="field is-horizontal field-body">
        <input
          class="input field"
          type="text"
          phx-blur="changing-key"
          phx-target={@myself}
          placeholder="Key"
        />
        <input
          class="input field"
          type="text"
          phx-blur="changing-value"
          phx-target={@myself}
          placeholder="Value"
        />
        <a class="button is-success field" phx-click="add" phx-target={@myself}>
          Add
        </a>
      </div>
    </fieldset>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove", %{"key" => key}, socket) do
    {:noreply, update(socket, :attributes, &Map.delete(&1, key))}
  end

  def handle_event("changing-key", %{"value" => value}, socket) do
    {:noreply, assign(socket, :new_key, value)}
  end

  def handle_event("changing-value", %{"value" => value}, socket) do
    {:noreply, assign(socket, :new_value, value)}
  end

  def handle_event("add", _params, %{assigns: assigns} = socket) do
    socket = update(socket, :attributes, &Map.put(&1, assigns.new_key, assigns.new_value))

    {:noreply, socket}
  end
end

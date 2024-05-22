defmodule SiwappWeb.TaxesComponent do
  @moduledoc false

  use SiwappWeb, :live_component

  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    "taxes-" <> index = assigns.id

    changeset = assigns.f.source

    selected =
      changeset
      |> Ecto.Changeset.get_field(:items)
      |> Enum.at(String.to_integer(index))
      |> Map.get(:taxes, [])
      |> Enum.map(&{&1.name, &1.id})
      |> MapSet.new()

    {:ok,
     socket
     |> assign(selected: selected)
     |> assign(name: assigns.name)
     |> assign(index: index)
     |> assign(options: MapSet.new(assigns.options))
     |> assign(changeset: changeset)
     |> assign(f: assigns.f)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="control msa-wrapper">
      <%= for {k, _v} <- @selected do %>
        <input type="hidden" name={"#{@name}[]"} value={k} />
      <% end %>
      <div class="input input-presentation" phx-click={JS.toggle(to: "#tag-list-#{@index}")}>
        <span class="placeholder"></span>
        <%= for {k, v} <- @selected do %>
          <div class="tag-badge">
            <span>
              <%= k %>
            </span>
            <button
              type="button"
              phx-click={JS.push("remove", target: @myself, value: %{index: @index, key: k, val: v})}
            >
              x
            </button>
          </div>
        <% end %>
      </div>
      <ul id={"tag-list-#{@index}"} class="tag-list" style="display: none;">
        <%= for {k, v} <- not_selected(@options, @selected) do %>
          <li phx-click={
            JS.push("add", target: @myself, value: %{index: @index, key: k, val: v})
            |> JS.toggle(to: "#tag-list-#{@index}")
          }>
            <%= k %>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove", %{"index" => index, "key" => key, "val" => value}, socket) do
    selected = MapSet.delete(socket.assigns.selected, {key, value})

    params =
      socket.assigns.f
      |> get_params()
      |> put_in(
        ["items", "#{index}", "taxes"],
        Enum.map(selected, fn {k, _v} -> k end)
      )

    send(self(), {:params_updated, params})

    {:noreply, socket}
  end

  def handle_event("add", %{"index" => index, "key" => key, "val" => value}, socket) do
    selected = MapSet.put(socket.assigns.selected, {key, value})

    params =
      socket.assigns.f
      |> get_params()
      |> put_in(
        ["items", "#{index}", "taxes"],
        Enum.map(selected, fn {k, _v} -> k end)
      )

    send(self(), {:params_updated, params})

    {:noreply, socket}
  end

  @spec not_selected(MapSet.t(), MapSet.t()) :: MapSet.t()
  defp not_selected(options, selected) do
    MapSet.difference(options, selected)
  end

  defp get_params(form) do
    case Map.keys(form.params) do
      [] ->
        items =
          form.data.items
          |> Enum.with_index(fn item, index -> {index, item} end)
          |> Enum.map(&convert_item/1)
          |> Map.new()

        %{"items" => items}

      _ ->
        form.params
    end
  end

  defp convert_item({index, item}) do
    {"#{index}",
     %{
       "_persistent_id" => index,
       "description" => item.description,
       "discount" => item.discount,
       "id" => item.id,
       "quantity" => item.quantity,
       "taxes" => Enum.map(item.taxes, fn t -> t.name end),
       "virtual_unitary_cost" => item.virtual_unitary_cost
     }}
  end
end

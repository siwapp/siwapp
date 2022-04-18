defmodule SiwappWeb.ItemsComponent do
  @moduledoc false

  use SiwappWeb, :live_component

  import SiwappWeb.PageView, only: [money_format: 3, money_format: 2]

  alias Ecto.Changeset
  alias SiwappWeb.InvoicesLive

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :multiselect_options, Siwapp.Commons.list_taxes_for_multiselect())}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(f: assigns.f)
     |> assign(changeset: assigns.f.source)
     |> assign(currency: Changeset.get_field(assigns.f.source, :currency))
     |> assign(inputs_for: assigns.inputs_for)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("add", _, socket) do
    params = socket.assigns.f.params

    next_item_index =
      params["items"]
      |> Enum.count()
      |> Integer.to_string()

    send(
      self(),
      {:params_updated, put_in(params, ["items", next_item_index], item_params())}
    )

    {:noreply, socket}
  end

  def handle_event("remove", %{"item-id" => item_index}, socket) do
    params =
      socket.assigns.f.params
      |> pop_in(["items", item_index])
      |> elem(1)
      |> Map.update!("items", &InvoicesLive.Edit.sort_indexes/1)

    send(self(), {:params_updated, params})

    {:noreply, socket}
  end

  @spec item_params() :: map
  defp item_params do
    %{
      "description" => "",
      "quantity" => "1",
      "discount" => "0",
      "unitary_cost" => "0",
      "taxes" => Siwapp.Commons.default_taxes_names()
    }
  end
end

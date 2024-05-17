defmodule SiwappWeb.ItemsComponent do
  @moduledoc false

  use SiwappWeb, :live_component

  import SiwappWeb.PageView, only: [money_format: 3, money_format: 2]

  alias Ecto.Changeset
  alias Phoenix.LiveView.JS

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, :multiselect_options, Siwapp.Commons.list_taxes_for_multiselect())}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(f: assigns.f)
     |> assign(currency: Changeset.get_field(assigns.f.source, :currency))}
  end
end

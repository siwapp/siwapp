defmodule SiwappWeb.UsersLive.FormComponent do
  @moduledoc false

  use SiwappWeb, :live_component
  alias Siwapp.Accounts
  alias Siwapp.Accounts.User

  @impl Phoenix.LiveComponent
  def update(%{user: user} = assigns, socket) do
    changeset = which_changeset(user, assigns.action)

    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.user
      |> which_changeset(user_params, socket.assigns.action)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)

    Accounts.delete_user(user)

    {:noreply,
     socket
     |> put_flash(:info, "User was successfully deleted.")
     |> push_redirect(to: socket.assigns.return_to)}
  end

  @spec save_user(Phoenix.LiveView.Socket.t(), :new | :edit, map()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User was successfully updated")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User was successfully created")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @spec which_changeset(User.t(), map, atom) :: Ecto.Changeset.t()
  defp which_changeset(user, user_params \\ %{}, action)

  defp which_changeset(user, user_params, :edit) do
    Accounts.change_user_registration(user, user_params, required: false)
  end

  defp which_changeset(user, user_params, :new) do
    Accounts.change_user_registration(user, user_params)
  end
end

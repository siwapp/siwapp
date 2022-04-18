defmodule SiwappWeb.UsersLive.Index do
  @moduledoc false
  use SiwappWeb, :live_view
  alias Siwapp.Accounts
  alias Siwapp.Accounts.User

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, check_admin(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl Phoenix.LiveView
  def handle_event("click_checkbox", params, socket) do
    checked = update_checked(params, socket)

    {:noreply, assign(socket, checked: checked)}
  end

  def handle_event("delete", _params, socket) do
    {info_or_error, msg, checked_users} =
      type_of_response(socket.assigns.checked, socket.assigns.current_user, :delete)

    if info_or_error == :info do
      checked_users
      |> Enum.map(&Accounts.get_user!(&1))
      |> Enum.each(&Accounts.delete_user(&1))
    end

    {:noreply,
     socket
     |> put_flash(info_or_error, msg)
     |> assign(:checked, MapSet.new())
     |> assign(:users, Accounts.list_users())}
  end

  def handle_event("upgrade_downgrade", _params, socket) do
    {info_or_error, msg, checked_users} =
      type_of_response(socket.assigns.checked, socket.assigns.current_user, :admin)

    if info_or_error == :info do
      checked_users
      |> Enum.map(&Accounts.get_user!(&1))
      |> Enum.each(&Accounts.update_user(&1, %{admin: not &1.admin}))
    end

    {:noreply,
     socket
     |> put_flash(info_or_error, msg)
     |> assign(:checked, MapSet.new())
     |> assign(:users, Accounts.list_users())}
  end

  def handle_event("redirect", %{"id" => id}, socket) do
    {:noreply, push_redirect(socket, to: Routes.users_index_path(socket, :edit, id))}
  end

  @spec check_admin(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  defp check_admin(socket) do
    if socket.assigns.current_user.admin do
      socket
      |> assign(:checked, MapSet.new())
      |> assign(:users, Accounts.list_users())
    else
      push_redirect(socket, to: Routes.user_session_path(socket, :new))
    end
  end

  @spec apply_action(Phoenix.LiveView.Socket.t(), :new | :edit | :index, map()) ::
          Phoenix.LiveView.Socket.t()
  defp apply_action(socket, :edit, %{"id" => id}) do
    user = Accounts.get_user!(id)

    socket
    |> assign(:page_title, user.email)
    |> assign(:user, user)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User")
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Users")
    |> assign(:user, nil)
  end

  @spec update_checked(map(), Phoenix.LiveView.Socket.t()) :: MapSet.t()
  defp update_checked(%{"id" => "0", "value" => "on"}, socket) do
    socket.assigns.users
    |> MapSet.new(& &1.id)
    |> MapSet.put(0)
  end

  defp update_checked(%{"id" => "0"}, _) do
    MapSet.new()
  end

  defp update_checked(%{"id" => id, "value" => "on"}, socket) do
    MapSet.put(socket.assigns.checked, String.to_integer(id))
  end

  defp update_checked(%{"id" => id}, socket) do
    socket.assigns.checked
    |> MapSet.delete(String.to_integer(id))
    |> MapSet.delete(0)
  end

  @spec type_of_response(MapSet.t(), User.t(), atom) :: {atom, binary, list}
  defp type_of_response(checked, current_user, atom) do
    checked
    |> MapSet.to_list()
    |> Enum.reject(&(&1 in [0, current_user.id]))
    |> check_if_list_is_empty(atom)
  end

  @spec check_if_list_is_empty(list, atom) :: {atom, binary, list}
  defp check_if_list_is_empty(list, atom) do
    if list == [] do
      {:error, type_of_error(atom), list}
    else
      {:info, type_of_info(atom), list}
    end
  end

  @spec type_of_error(atom) :: binary()
  defp type_of_error(:delete) do
    "You can´t delete yourself"
  end

  defp type_of_error(:admin) do
    "You can´t downgrade yourself"
  end

  @spec type_of_info(atom) :: binary()
  defp type_of_info(:delete) do
    "Users succesfully deleted"
  end

  defp type_of_info(:admin) do
    "Users succesfully updated"
  end
end

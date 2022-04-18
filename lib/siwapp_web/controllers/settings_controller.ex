defmodule SiwappWeb.SettingsController do
  use SiwappWeb, :controller

  alias Siwapp.Invoices
  alias Siwapp.Settings

  @spec edit(Plug.Conn.t(), map) :: Plug.Conn.t()
  def edit(conn, _params) do
    data = Settings.current_bundle()
    changeset = Settings.change_bundle(data)

    conn
    |> assign(:changeset, changeset)
    |> assign(:currency_options, Invoices.list_currencies())
    |> assign(:page_title, "Settings")
    |> render("edit.html")
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(conn, %{"setting_bundle" => attrs}) do
    case Settings.apply_user_bundle(attrs) do
      {:ok, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:currency_options, Invoices.list_currencies())
        |> put_flash(:info, "Settings saved succesfully")
        |> render("edit.html")

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end
end

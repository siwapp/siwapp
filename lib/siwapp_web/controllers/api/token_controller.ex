defmodule SiwappWeb.Api.TokenController do
  use SiwappWeb, :controller

  alias Siwapp.Accounts
  alias Siwapp.Accounts.User
  alias Siwapp.ApiToken

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"email" => email, "password" => password}) do
    with %User{} = user <- Accounts.get_user_by_email_and_password(email, password),
         token <- ApiToken.sign(%{user_id: user.id}) do
      render(conn, "token.json", token: token)
    else
      nil ->
        render(conn, "error.json", error_message: "Invalid email or password")
    end
  end
end

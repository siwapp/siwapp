defmodule SiwappWeb.Api.TokenView do
  @moduledoc false
  use SiwappWeb, :view

  @spec render(binary, map) :: map()
  def render("token.json", %{token: token}) do
    %{token: token}
  end

  def render("error.json", %{error_message: error_message}) do
    %{error_message: error_message}
  end

  def render("valid_token.json", %{email: email}) do
    %{message: "Your token is valid. You're correctly authenticated as #{email}"}
  end
end

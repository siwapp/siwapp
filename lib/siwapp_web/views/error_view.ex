defmodule SiwappWeb.ErrorView do
  @moduledoc false
  use SiwappWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.html", _assigns) do
  #   "Internal Server Error"
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.html" becomes
  # "Not Found".

  # This pattern match is to make sure that the api calls
  # receiving 404 do receive this text instead of the
  # current template
  def render("404.html", %{conn: %{path_info: ["api" | _]}}), do: "Not Found"
end

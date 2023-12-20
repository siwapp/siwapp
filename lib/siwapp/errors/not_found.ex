defmodule Siwapp.Error.NotFoundError do
  defexception message: "Not found", plug_status: 404, type: "", id: ""
end

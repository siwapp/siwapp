defmodule Siwapp.Sentry do
  @moduledoc """
  Module for configuring Sentry
  """

  defmodule EventFilter do
    @moduledoc """
    Module for filtering events sending to Sentry
    """

    @behaviour Sentry.EventFilter

    @spec exclude_exception?(struct, atom) :: boolean
    def exclude_exception?(%Siwapp.Error.NotFoundError{}, _), do: true
    def exclude_exception?(%Phoenix.Router.NoRouteError{}, _), do: true
    def exclude_exception?(_exception, _source), do: false
  end
end

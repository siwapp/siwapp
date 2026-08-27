defmodule Siwapp.Sentry do
  @moduledoc """
  Module for configuring Sentry
  """

  @spec before_send(Sentry.Event.t()) :: Sentry.Event.t() | false
  def before_send(%Sentry.Event{original_exception: %Ecto.NoResultsError{}}), do: false
  def before_send(%Sentry.Event{original_exception: %Phoenix.Router.NoRouteError{}}), do: false
  def before_send(event), do: event
end

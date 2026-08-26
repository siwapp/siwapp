defmodule Siwapp.SentryTest do
  use ExUnit.Case, async: true

  alias Siwapp.Sentry, as: SentryConfig

  test "filters expected exceptions" do
    no_results = event(%Ecto.NoResultsError{})
    no_route = event(%Phoenix.Router.NoRouteError{})

    assert SentryConfig.before_send(no_results) == false
    assert SentryConfig.before_send(no_route) == false
  end

  test "keeps other events" do
    event = event(%RuntimeError{})

    assert SentryConfig.before_send(event) == event
  end

  defp event(exception) do
    %Sentry.Event{
      event_id: String.duplicate("0", 32),
      timestamp: 0,
      original_exception: exception
    }
  end
end

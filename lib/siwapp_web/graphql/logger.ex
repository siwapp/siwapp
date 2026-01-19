defmodule SiwappWeb.GraphQL.Logger do
  @moduledoc """
  Standard logger for GraphQL
  """

  @behaviour Absinthe.Middleware
  require Logger

  @impl Absinthe.Middleware
  def call(resolution, _config) do
    operation_name = resolution.definition.name || "unnamed"

    variables =
      resolution.arguments
      |> Phoenix.Logger.filter_values({:discard, "password"})
      |> Jason.encode!(pretty: [indent: "", line_separator: "", after_colon: ""])

    Logger.metadata(graphql: operation_name)
    Logger.metadata(graphql_variables: variables)

    resolution
  end
end

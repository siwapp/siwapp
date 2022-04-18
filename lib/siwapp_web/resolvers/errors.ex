defmodule SiwappWeb.Resolvers.Errors do
  @moduledoc """
  Error helpers for GraphQL.
  """

  @doc """
  Extracts the errors from a changeset, to display them
  into a GraphQL response.
  """
  @spec extract(Ecto.Changeset.t()) :: map
  def extract(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end

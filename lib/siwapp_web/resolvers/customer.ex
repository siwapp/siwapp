defmodule SiwappWeb.Resolvers.Customer do
  @moduledoc """
  Customers functions for GraphQL
  """

  alias Siwapp.Customers
  alias SiwappWeb.Resolvers.Errors
  alias SiwappWeb.Resolvers.Helpers

  @spec list(map(), Absinthe.Resolution.t()) :: {:ok, [Customers.Customer.t()]}
  def list(%{limit: limit, offset: offset}, _resolution) do
    {:ok, Customers.list(limit, offset)}
  end

  @spec create(map(), Absinthe.Resolution.t()) :: {:error, map()} | {:ok, Customers.Customer.t()}
  def create(args, _resolution) do
    args = Helpers.maybe_change_meta_attributes(args)

    case Customers.create(args) do
      {:ok, customer} ->
        {:ok, customer}

      {:error, changeset} ->
        {:error, message: "Failed!", details: Errors.extract(changeset)}
    end
  end

  @spec delete(map, Absinthe.Resolution.t()) :: {:error, map()} | {:ok, Customers.Customer.t()}
  def delete(%{id: id}, _resolution) do
    customer = Customers.get(id)

    if is_nil(customer) do
      {:error, message: "Failed!", details: "Customer not found"}
    else
      Customers.delete(customer)
    end
  end
end

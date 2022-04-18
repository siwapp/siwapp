defmodule Siwapp.CustomersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Siwapp.Customers` context.
  """

  alias Siwapp.Customers
  alias Siwapp.Customers.Customer

  @spec unique_customer_name :: binary
  def unique_customer_name, do: "#{System.unique_integer()}"

  @spec unique_customer_identification :: binary
  def unique_customer_identification, do: "#{System.unique_integer()}"

  @spec unique_customer_email :: binary
  def unique_customer_email, do: "customer#{System.unique_integer()}@example.com"

  @spec valid_customer_attributes(map()) :: map()
  def valid_customer_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_customer_email(),
      identification: unique_customer_identification(),
      name: unique_customer_name()
    })
  end

  @spec customer_fixture(map()) :: Customer.t()
  def customer_fixture(attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> valid_customer_attributes()
      |> Customers.create()

    customer
  end

  @spec customer_with_totals(non_neg_integer()) :: Customer.t()
  def customer_with_totals(customer_id) do
    Customer
    |> Siwapp.Query.by(:id, customer_id)
    |> Customers.list_with_assoc_invoice_fields()
    |> List.first()
  end
end

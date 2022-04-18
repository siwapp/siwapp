defmodule Siwapp.Customers.CustomerQuery do
  @moduledoc """
  Module to manage Customer queries
  """
  import Ecto.Query

  alias Siwapp.Customers.Customer

  @doc """
  Query to get customers in db, ordered desc. by id with limit and offset
  """
  @spec list(non_neg_integer(), non_neg_integer()) :: Ecto.Query.t()
  def list(limit, offset) do
    Customer
    |> order_by(desc: :id)
    |> limit(^limit)
    |> offset(^offset)
  end

  @doc """
  Query to get customers in db, ordered desc. by id with limit and offset
  just selecting fields: id, name, identification; and virtual fields: total,
  paid and currencies (sum of gross amount, sum of paid amount and list of
  all currencies, respectively, used in all invoices associated to customer)
  """
  @spec list_with_assoc_invoice_fields(Ecto.Queryable.t(), non_neg_integer(), non_neg_integer()) ::
          Ecto.Query.t()
  def list_with_assoc_invoice_fields(query, limit, offset) do
    query
    |> from(as: :query)
    |> order_by(desc: :id)
    |> limit(^limit)
    |> offset(^offset)
    |> join(:left, [query: c], i in Siwapp.Invoices.Invoice,
      on: c.id == i.customer_id and not (i.draft or i.failed or not is_nil(i.deleted_at)),
      as: :inv
    )
    |> group_by([query: c], c.id)
    |> select([query: c, inv: i], %Customer{
      total: coalesce(sum(i.gross_amount), 0),
      paid: coalesce(sum(i.paid_amount), 0),
      currencies: fragment("COALESCE(NULLIF(array_agg(?), '{NULL}'), '{}')", i.currency),
      name: c.name,
      identification: c.identification,
      id: c.id
    })
  end

  @spec names(binary, non_neg_integer) :: Ecto.Query.t()
  def names(value, page) do
    offset_by = 10 * page

    Customer
    |> select([q], q.name)
    |> where([q], ilike(q.name, ^"%#{value}%"))
    |> limit(10)
    |> offset(^offset_by)
  end
end

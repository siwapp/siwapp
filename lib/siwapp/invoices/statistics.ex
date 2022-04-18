defmodule Siwapp.Invoices.Statistics do
  @moduledoc """
  Statistics utils.
  """
  import Ecto.Query

  alias Siwapp.Invoices.Invoice
  alias Siwapp.Query
  alias Siwapp.Repo

  @spec count(Ecto.Queryable.t(), keyword()) :: non_neg_integer()
  def count(query, options \\ []) do
    default = [deleted_at_query: false]
    options = Keyword.merge(default, options)

    query
    |> then(&if(options[:deleted_at_query], do: Query.not_deleted(&1), else: &1))
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns a list of tuples, each containing the accumulated amount of money from all the invoices
  per day, for the given selection of 'invoices'.
  """
  @spec get_amount_per_day(Ecto.Queryable.t()) :: [{Date.t(), non_neg_integer()}]
  def get_amount_per_day(query \\ Invoice) do
    query
    |> Query.not_deleted()
    |> group_by([q], q.issue_date)
    |> select([q], %{date: q.issue_date, amount: sum(q.gross_amount)})
    |> subquery()
    |> join(
      :right,
      [q],
      d in fragment(
        "select i.date from generate_series(current_date - interval '30 day', current_date, '1 day') as i"
      ),
      on: q.date == d.date
    )
    |> select([q, d], {d.date, coalesce(q.amount, 0)})
    |> Repo.all()
  end

  @doc """
  Returns a tuple with the number of invoices found and a map in which each key is the string of a currency code and its value the accumulated amount
  corresponding to all the 'invoices' in that currency.
  """
  @spec get_amount_per_currencies_and_count(Ecto.Queryable.t(), atom) :: {map, non_neg_integer()}
  def get_amount_per_currencies_and_count(query \\ Invoice, type_of_amount) do
    [{count, total}] =
      query
      |> Query.not_deleted()
      |> group_by([q], q.currency)
      |> select_amount_and_count(type_of_amount)
      |> subquery()
      |> select(
        [sbq],
        {sum(sbq.num_of_inv), fragment("array_agg((?, ?))", sbq.currency, sbq.total)}
      )
      |> Repo.all()

    if is_nil(total) do
      {%{}, 0}
    else
      {Map.new(total), count}
    end
  end

  @spec get_tax_amount_per_currencies(Ecto.Queryable.t()) :: %{binary() => [tuple()]} | %{}
  def get_tax_amount_per_currencies(query \\ Invoice) do
    final_query =
      from(
        sbq in subquery(
          query
          |> Query.not_deleted()
          |> join(:inner, [q], q in assoc(q, :items), as: :items)
          |> join(:inner, [items: itm], itm in assoc(itm, :taxes), as: :taxes)
          |> group_by([q, taxes: t], [q.currency, q.id, t.name])
          |> select(
            [q, items: itm, taxes: t],
            %{
              total:
                fragment(
                  "round(sum(?*?*(1-?::decimal/100)*?::decimal/100))",
                  itm.quantity,
                  itm.unitary_cost,
                  itm.discount,
                  t.value
                ),
              name: t.name,
              currency: q.currency
            }
          )
        ),
        group_by: [sbq.name, sbq.currency],
        select: {sbq.name, sbq.currency, fragment("sum(total)")}
      )

    final_query
    |> Repo.all()
    |> restructure()
  end

  @spec select_amount_and_count(Ecto.Queryable.t(), atom) :: Ecto.Queryable.t()
  defp select_amount_and_count(query, :gross) do
    select(query, [q], %{
      num_of_inv: count(q.id),
      currency: q.currency,
      total: sum(q.gross_amount)
    })
  end

  defp select_amount_and_count(query, :net) do
    select(query, [q], %{num_of_inv: count(q.id), currency: q.currency, total: sum(q.net_amount)})
  end

  @spec restructure([tuple]) :: %{binary() => [tuple()]} | %{}
  defp restructure(list) do
    Enum.reduce(list, %{}, fn tuple, acc ->
      {tax_name, currency, total} = tuple

      if Map.has_key?(acc, tax_name) do
        Map.update!(
          acc,
          tax_name,
          &(&1
            |> Kernel.++([{currency, Decimal.to_integer(total)}])
            |> Enum.sort())
        )
      else
        Map.put(acc, tax_name, [{currency, Decimal.to_integer(total)}])
      end
    end)
  end
end

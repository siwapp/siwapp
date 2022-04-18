defmodule Siwapp.Searches do
  @moduledoc """
  Search Context
  """
  import Ecto.Query
  alias Siwapp.Customers.CustomerQuery
  alias Siwapp.Query
  alias Siwapp.Repo
  alias Siwapp.Searches.Search
  alias Siwapp.Searches.SearchQuery

  @type type_of_struct ::
          Siwapp.Invoices.Invoice.t()
          | Siwapp.Customers.Customer.t()
          | Siwapp.RecurringInvoices.RecurringInvoice.t()
  @doc """
  Filter invoices, customers or recurring_invoices by the selected parameters
  """
  @spec filters(Ecto.Queryable.t(), keyword()) :: [type_of_struct()]
  def filters(query, options \\ []) do
    default = [limit: 20, offset: 0, preload: [], order_by: [desc: :id], deleted_at_query: false]
    options = Keyword.merge(default, options)

    query
    |> then(&if(options[:deleted_at_query], do: Query.not_deleted(&1), else: &1))
    |> limit(^options[:limit])
    |> offset(^options[:offset])
    |> order_by(^options[:order_by])
    |> Query.list_preload(options[:preload])
    |> Repo.all()
  end

  @doc """
  Returns a query for the filter_params
  """
  @spec filters_query(Ecto.Queryable.t(), [{binary, binary}] | map()) :: Ecto.Queryable.t()
  def filters_query(query, params) do
    Enum.reduce(params, query, fn {key, value}, acc_query ->
      SearchQuery.filter_by(acc_query, key, value)
    end)
  end

  @doc """
  Returns 10 customers names starting from an offset(10*page) that match with the value
  """
  @spec get_customers_names(binary, non_neg_integer) :: list()
  def get_customers_names(value, page) do
    Repo.all(CustomerQuery.names(value, page))
  end

  @spec change(Search.t(), map) :: Ecto.Changeset.t()
  def change(%Search{} = search, attrs \\ %{}) do
    Search.changeset(search, attrs)
  end
end

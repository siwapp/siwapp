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
  def filters_query(query, params) when is_list(params) do
    filters_query(query, Map.new(params))
  end

  def filters_query(query, params) do
    params
    |> transform_params()
    |> Enum.reduce(query, fn {key, value}, acc_query ->
      SearchQuery.filter_by(acc_query, key, value)
    end)
  end

  @spec transform_params(map) :: map
  defp transform_params(params) do
    {key, params} = Map.pop(params, "key")
    {value, params} = Map.pop(params, "value")

    if not is_nil(key) and not is_nil(value) do
      # Transform params 'key' and 'value' into a single param 'meta_attribute'
      Map.put(params, "meta_attribute", {key, value})
    else
      params
    end
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

  @spec prepare_order_by(atom, atom) :: Keyword.t()
  def prepare_order_by(order, :name), do: [{order, dynamic([p], fragment("lower(?)", p.name))}]
  def prepare_order_by(order, field), do: [{order, field}]
end

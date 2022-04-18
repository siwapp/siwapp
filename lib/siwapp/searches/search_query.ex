defmodule Siwapp.Searches.SearchQuery do
  @moduledoc """
  Search Queries
  """
  import Ecto.Query
  alias Siwapp.Invoices.InvoiceQuery
  alias Siwapp.Query
  alias Siwapp.RecurringInvoices.RecurringInvoiceQuery

  @doc """
  For each key, one different query
  """
  @spec filter_by(Ecto.Queryable.t(), binary, binary) :: Ecto.Queryable.t()
  def filter_by(query, "search_input", value) do
    name_email_or_id(query, value)
  end

  def filter_by(query, "name", value) do
    Query.search_in_string(query, convert_to_atom("name"), value)
  end

  def filter_by(query, "number", value) do
    where(query, [q], q.number == type(^value, :integer))
  end

  def filter_by(query, "customer_id", value) do
    where(query, [q], q.customer_id == type(^value, :integer))
  end

  def filter_by(query, "series", value) do
    query
    |> from(as: :query)
    |> join(:inner, [query: q], s in Siwapp.Commons.Series, on: q.series_id == s.id, as: :series)
    |> where([query: q, series: s], ilike(s.name, ^value))
  end

  def filter_by(query, date, value)
      when date in [
             "issue_from_date",
             "issue_to_date",
             "starting_from_date",
             "starting_to_date",
             "finishing_from_date",
             "finishing_to_date"
           ] do
    value = Date.from_iso8601!(value)

    type_of_date(query, date, value)
  end

  def filter_by(query, "status", value) do
    type_of_status(query, value)
  end

  def filter_by(query, "key", value) do
    join(query, :inner, [q], m in fragment("jsonb_each_text(?)", q.meta_attributes),
      on: m.key == ^value
    )
  end

  def filter_by(query, "value", value) do
    query
    |> join(:inner, [q], m in fragment("jsonb_each_text(?)", q.meta_attributes),
      on: m.value == ^value
    )
    |> distinct(true)
  end

  # Get invoices, customers or recurring_invoices by comparing value with name, email or id fields
  @spec name_email_or_id(Ecto.Queryable.t(), binary) :: Ecto.Queryable.t()
  defp name_email_or_id(query, value) do
    where(
      query,
      [q],
      ilike(q.name, ^"%#{value}%") or ilike(q.email, ^"%#{value}%") or
        ilike(q.identification, ^"%#{value}%")
    )
  end

  # There are 6 types of dates; 3 "to_dates" and 3 "from_dates". Depending on the key name,
  # the function will make different queries
  @spec type_of_date(Ecto.Queryable.t(), binary, Date.t()) :: Ecto.Queryable.t()
  defp type_of_date(query, key, value) do
    cond do
      String.starts_with?(key, "issue_from") ->
        InvoiceQuery.issue_date_gteq(query, value)

      String.starts_with?(key, "issue_to") ->
        InvoiceQuery.issue_date_lteq(query, value)

      String.starts_with?(key, "starting_from") ->
        RecurringInvoiceQuery.starting_date_gteq(query, value)

      String.starts_with?(key, "starting_to") ->
        RecurringInvoiceQuery.starting_date_lteq(query, value)

      String.starts_with?(key, "finishing_from") ->
        RecurringInvoiceQuery.finishing_date_gteq(query, value)

      true ->
        RecurringInvoiceQuery.finishing_date_lteq(query, value)
    end
  end

  # It implements the same algorithm of the Invoices Context Status function.
  # If a user filters by draft, paid or failed,
  # the query will search if the field with same name as value is true.
  # If user filters by pending, the query will search if draft, paid and failed are false and also if due_date is nil
  # or if due_date is greater than today
  # Finally if user filters by past due, the query will do the same as pending, but in this case due_date must exists
  # and has to be less than today
  @spec type_of_status(Ecto.Queryable.t(), binary) :: Ecto.Queryable.t()
  defp type_of_status(query, value) do
    case value do
      v when v in ["draft", "paid", "failed"] ->
        value = convert_to_atom(value)

        where(query, [q], field(q, ^value) == true)

      "pending" ->
        InvoiceQuery.pending(query)

      "past_due" ->
        InvoiceQuery.past_due(query)
    end
  end

  @spec convert_to_atom(binary) :: atom
  defp convert_to_atom(value) do
    value
    |> String.downcase()
    |> String.to_atom()
  end
end

defmodule SiwappWeb.Resolvers.Invoice do
  @moduledoc """
  Invoices functions for GraphQL
  """

  alias Siwapp.Invoices
  alias Siwapp.Repo
  alias SiwappWeb.PageView
  alias SiwappWeb.Resolvers.Errors
  alias SiwappWeb.Resolvers.Helpers

  @spec get(map, Absinthe.Resolution.t()) :: {:ok, map} | {:error, binary}
  def get(%{id: id}, _resolution) do
    case Invoices.get(id) do
      nil -> {:error, "Invoice with id #{id} not found."}
      invoice -> {:ok, set_reference(invoice)}
    end
  end

  @spec list(map(), Absinthe.Resolution.t()) :: {:ok, [Invoices.Invoice.t()]}
  def list(%{limit: limit, offset: offset} = params, _resolution) do
    filters = get_filters(params)

    invoices =
      Invoices.list(
        limit: limit,
        offset: offset,
        preload: [:items, :payments, :series, :customer],
        filters: filters
      )

    invoices =
      Enum.map(invoices, fn invoice ->
        invoice
        |> set_correct_units()
        |> set_status()
        |> set_reference()
      end)

    {:ok, invoices}
  end

  @spec create(map(), Absinthe.Resolution.t()) :: {:error, map()} | {:ok, Invoices.Invoice.t()}
  def create(args, _resolution) do
    args = Helpers.maybe_change_meta_attributes(args)

    case Invoices.create(args) do
      {:ok, invoice} ->
        {:ok,
         invoice
         |> set_reference()
         |> set_correct_units()}

      {:error, changeset} ->
        {:error, message: "Failed!", details: Errors.extract(changeset)}
    end
  end

  @spec update(map(), Absinthe.Resolution.t()) :: {:error, map()} | {:ok, Invoices.Invoice.t()}
  def update(%{id: id} = params, _resolution) do
    invoice = Invoices.get(id)

    params = Helpers.maybe_change_meta_attributes(params)

    if is_nil(invoice) do
      {:error, message: "Failed!", details: "Invoice not found"}
    else
      case Invoices.update(invoice, params) do
        {:ok, invoice} ->
          {:ok,
           invoice
           |> set_reference()
           |> set_correct_units()}

        {:error, changeset} ->
          {:error, message: "Failed!", details: Errors.extract(changeset)}
      end
    end
  end

  @spec delete(map(), Absinthe.Resolution.t()) :: {:error, map()} | {:ok, Invoices.Invoice.t()}
  def delete(%{id: id}, _resolution) do
    invoice = Invoices.get(id)

    if is_nil(invoice) do
      {:error, message: "Failed!", details: "Invoice not found"}
    else
      Invoices.delete(invoice)
    end
  end

  def format_amount(field, invoice, args, _resolution) do
    amount_in_cents = Map.fetch!(invoice, field)

    case args do
      %{format: "cents"} ->
        {:ok, amount_in_cents}

      %{format: "unit"} ->
        {:ok, PageView.money_format(amount_in_cents, nil, symbol: false)}

      _ ->
        # legacy value may either be in cents or units depending on the query/mutation
        {:ok, Map.get(invoice, :"legacy_#{field}", amount_in_cents)}
    end
  end

  # Deprecated: amounts are now transformed in the resolver
  @spec set_correct_units(Invoices.Invoice.t()) :: Invoices.Invoice.t()
  defp set_correct_units(invoice) do
    Enum.reduce([:net_amount, :gross_amount, :paid_amount], invoice, fn key, invoice ->
      # This is for backwards compatibility so format_amount/3 can return the legacy value
      # when no specfic format is requested
      Map.update(invoice, :"legacy_#{key}", 0, fn existing_value ->
        PageView.money_format(existing_value, invoice.currency, symbol: false)
      end)
    end)
  end

  @spec set_status(Invoices.Invoice.t()) :: map
  defp set_status(invoice) do
    Map.put(invoice, :status, Atom.to_string(Invoices.status(invoice)))
  end

  @spec set_reference(map) :: map
  defp set_reference(%Invoices.Invoice{draft: true} = invoice), do: invoice

  defp set_reference(invoice) do
    invoice
    |> Repo.preload(:series)
    |> then(&Map.put(&1, :reference, "#{&1.series.code}-#{Map.get(&1, :number)}"))
  end

  @spec get_filters(map()) :: Keyword.t()
  defp get_filters(params) do
    params
    |> Map.drop([:limit, :offset])
    |> with_status_params()
    |> with_issue_date()
    |> meta_attributes_params()
    |> Map.to_list()
  end

  @spec with_status_params(map()) :: map()
  defp with_status_params(%{with_status: status} = params),
    do: Map.put(params, :with_status, String.to_existing_atom(status))

  defp with_status_params(params), do: params

  @spec with_issue_date(map()) :: map()
  defp with_issue_date(%{from_issue_date: issue_date_gteq} = params) do
    params
    |> Map.delete(:from_issue_date)
    |> Map.put(:issue_date_gteq, issue_date_gteq)
    |> with_issue_date()
  end

  defp with_issue_date(%{to_issue_date: issue_date_lteq} = params) do
    params
    |> Map.delete(:to_issue_date)
    |> Map.put(:issue_date_lteq, issue_date_lteq)
    |> with_issue_date()
  end

  defp with_issue_date(params), do: params

  @spec meta_attributes_params(map()) :: map()
  defp meta_attributes_params(%{meta_attributes: meta_attributes} = params) do
    meta_attributes = Enum.reduce(meta_attributes, %{}, &Map.put(&2, &1.key, &1.value))
    Map.put(params, :meta_attributes, meta_attributes)
  end

  defp meta_attributes_params(params), do: params
end

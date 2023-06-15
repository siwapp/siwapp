defmodule SiwappWeb.Resolvers.Invoice do
  @moduledoc """
  Invoices functions for GraphQL
  """

  alias Siwapp.Invoices
  alias SiwappWeb.PageView
  alias SiwappWeb.Resolvers.Errors
  alias SiwappWeb.Resolvers.Helpers

  @spec get(map(), Absinthe.Resolution.t()) :: {:ok, Invoices.Invoice.t()}
  def get(%{id: id}, _resolution) do
    invoice = Invoices.get!(id, preload: [:items, :payments])

    {:ok, invoice}
  end

  @spec list(map(), Absinthe.Resolution.t()) :: {:ok, [Invoices.Invoice.t()]}
  def list(%{limit: limit, offset: offset} = params, _resolution) do
    filters = get_filters(params)

    invoices =
      Invoices.list(
        limit: limit,
        offset: offset,
        preload: [:items, :payments, :series],
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
        {:ok, set_correct_units(invoice)}

      {:error, changeset} ->
        {:error, message: "Failed!", details: Errors.extract(changeset)}
    end
  end

  @spec update(map(), Absinthe.Resolution.t()) :: {:error, map()} | {:ok, Invoices.Invoice.t()}
  def update(%{id: id} = params, _resolution) do
    invoice = Invoices.get(id, preload: [:customer, {:items, :taxes}, :payments, :series])

    params = Helpers.maybe_change_meta_attributes(params)

    if is_nil(invoice) do
      {:error, message: "Failed!", details: "Invoice not found"}
    else
      case Invoices.update(invoice, params) do
        {:ok, invoice} ->
          {:ok, set_correct_units(invoice)}

        {:error, changeset} ->
          {:error, message: "Failed!", details: Errors.extract(changeset)}
      end
    end
  end

  @spec delete(map(), Absinthe.Resolution.t()) :: {:error, map()} | {:ok, Invoices.Invoice.t()}
  def delete(%{id: id}, _resolution) do
    invoice = Invoices.get(id, preload: [{:items, :taxes}, :payments])

    if is_nil(invoice) do
      {:error, message: "Failed!", details: "Invoice not found"}
    else
      Invoices.delete(invoice)
    end
  end

  @spec set_correct_units(Invoices.Invoice.t()) :: Invoices.Invoice.t()
  defp set_correct_units(invoice) do
    Enum.reduce([:net_amount, :gross_amount, :paid_amount], invoice, fn key, invoice ->
      Map.update(invoice, key, 0, fn existing_value ->
        PageView.money_format(existing_value, invoice.currency, symbol: false)
      end)
    end)
  end

  @spec set_status(Invoices.Invoice.t()) :: map
  defp set_status(invoice) do
    Map.put(invoice, :status, Atom.to_string(Invoices.status(invoice)))
  end

  @spec set_reference(map) :: map
  defp set_reference(invoice) do
    Map.put(invoice, :reference, "#{invoice.series.code}-#{Map.get(invoice, :number)}")
  end

  @spec get_filters(map()) :: Keyword.t()
  defp get_filters(params) do
    params
    |> Map.drop([:limit, :offset])
    |> with_status_params()
    |> meta_attributes_params()
    |> Map.to_list()
  end

  @spec with_status_params(map()) :: map()
  defp with_status_params(%{with_status: status} = params),
    do: Map.put(params, :with_status, String.to_existing_atom(status))

  defp with_status_params(params), do: params

  @spec meta_attributes_params(map()) :: map()
  defp meta_attributes_params(%{meta_attributes: meta_attributes} = params) do
    meta_attributes = Enum.reduce(meta_attributes, %{}, &Map.put(&2, &1.key, &1.value))
    Map.put(params, :meta_attributes, meta_attributes)
  end

  defp meta_attributes_params(params), do: params
end

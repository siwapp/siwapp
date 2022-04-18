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
  def list(%{customer_id: customer_id, limit: limit, offset: offset}, _resolution) do
    invoices =
      Invoices.list(
        limit: limit,
        offset: offset,
        preload: [:items, :payments],
        filters: [customer_id: customer_id]
      )

    invoices = Enum.map(invoices, &set_correct_units/1)

    {:ok, invoices}
  end

  def list(%{limit: limit, offset: offset}, _resolution) do
    invoices = Invoices.list(limit: limit, offset: offset, preload: [:items, :payments])
    invoices = Enum.map(invoices, &set_correct_units/1)

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
end

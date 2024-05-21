defmodule Siwapp.InvoiceHelper do
  @moduledoc """
  Helper functions for Invoice and RecurringInvoice schemas
  """

  import Ecto.Changeset

  alias Siwapp.Invoices.AmountHelper
  alias Siwapp.Customers
  alias Siwapp.Customers.Customer
  alias Siwapp.Invoices.Item

  @spec maybe_find_customer_or_new(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def maybe_find_customer_or_new(changeset) do
    if is_nil(get_field(changeset, :customer_id)) do
      find_customer_or_new(changeset)
    else
      if changes_in_name_or_identification?(changeset) do
        find_customer_or_new(changeset)
      else
        changeset
      end
    end
  end

  @spec assign_currency(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def assign_currency(changeset) do
    if get_field(changeset, :currency) do
      changeset
    else
      put_change(changeset, :currency, Siwapp.Settings.value(:currency))
    end
  end

  @doc """
  Performs the totals calculations for net_amount, taxes_amounts and gross_amount fields.
  """
  def calculate_invoice(invoice) do
    invoice
    |> with_virtual_fields()
    |> set_items_virtuals()
    |> set_net_amount_invoice()
    |> set_taxes_amounts_invoice()
    |> set_gross_amount_invoice()
  end

  # Sets virtual fields to payments and items
  @spec with_virtual_fields(Invoice.t()) :: Invoice.t()
  defp with_virtual_fields(invoice) do
    invoice
    |> AmountHelper.set_virtual_amounts(:payments, :virtual_amount, :amount)
    |> AmountHelper.set_virtual_amounts(:items, :virtual_unitary_cost, :unitary_cost)
  end

  defp set_items_virtuals(invoice) do
    items = Enum.map(invoice.items, fn item ->
      {base_amount, net_amount} = Item.get_amounts(item.quantity, item.unitary_cost, item.discount)
      taxes = Item.get_taxes_amount(item.taxes, net_amount)
      item
      |> Map.put(:taxes_amount, taxes)
      |> Map.put(:base_amount, base_amount)
      |> Map.put(:net_amount, net_amount)
    end)
    Map.put(invoice, :items, items)
  end

  @spec find_customer_or_new(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp find_customer_or_new(changeset) do
    identification = get_field(changeset, :identification)
    name = get_field(changeset, :name)

    case Customers.get(identification, name) do
      nil ->
        customer_changeset = Customer.changeset(%Customer{}, changeset.changes)

        changeset
        |> put_assoc(:customer, customer_changeset)
        |> bring_customer_errors()

      customer ->
        put_change(changeset, :customer_id, customer.id)
    end
  end

  @spec changes_in_name_or_identification?(Ecto.Changeset.t()) :: boolean()
  defp changes_in_name_or_identification?(changeset) do
    Map.has_key?(changeset.changes, :name) or
      Map.has_key?(changeset.changes, :identification)
  end

  @spec bring_customer_errors(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp bring_customer_errors(changeset) do
    changeset
    |> traverse_errors(& &1)
    |> Map.get(:customer, [])
    |> Enum.reduce(changeset, fn error, new_changeset ->
      add_error(new_changeset, error)
    end)
  end

  @spec add_error(Ecto.Changeset.t(), {atom, list()}) :: Ecto.Changeset.t()
  defp add_error(changeset, {key, [{message, opts}]}),
    do: add_error(changeset, key, message, opts)

  defp set_net_amount_invoice(invoice) do
    case Map.get(invoice, :items) do
      nil -> invoice
      items ->
        total_net_amount =
          items
          |> Enum.map(& &1.net_amount)
          |> Enum.sum()

        Map.put(invoice, :net_amount, total_net_amount)
    end
  end

  defp set_taxes_amounts_invoice(invoice) do
    case Map.get(invoice, :items) do
      nil -> invoice
      items ->
        total_taxes_amounts =
          items
          |> Enum.map(& &1.taxes_amount)
          |> Enum.reduce(%{}, &Map.merge(&1, &2, fn _, v1, v2 -> Decimal.add(v1, v2) end))
          |> Enum.map(fn {k, v} -> {k, v |> Decimal.round() |> Decimal.to_integer()} end)
          |> Map.new()

        Map.put(invoice, :taxes_amounts, total_taxes_amounts)
    end
  end

  defp set_gross_amount_invoice(invoice) do
    case Map.get(invoice, :items) do
      nil -> invoice
      _items ->
        taxes_amount =
          invoice.taxes_amounts
          |> Map.values()
          |> Enum.sum()

      gross_amount = invoice.net_amount + taxes_amount

      Map.put(invoice, :gross_amount, gross_amount)
    end
  end

end

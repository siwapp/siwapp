defmodule Siwapp.Invoices.AmountHelper do
  @moduledoc """
  Helper functions for Item and Payments schemas when handling with amounts
  """

  alias Siwapp.Invoices.Invoice

  @doc """
  Given an invoice it sets the virtual amounts from the real amounts
  of the payments and items in order to show them correctly in the forms.
  """
  @spec set_virtual_amounts(Invoice.t(), atom, atom, atom) :: Invoice.t()
  def set_virtual_amounts(invoice, key, virtual_field, field) do
    items = Map.get(invoice, key)

    if is_list(items) do
      new_items =
        Enum.map(items, fn i ->
          virtual = get_virtual_amount(Map.get(i, field), invoice.currency)
          Map.put(i, virtual_field, virtual)
        end)

      Map.put(invoice, key, new_items)
    else
      invoice
    end
  end

  @doc """
  Modifies the payments and item attrs getting the value from the virtual fields
  and setting the right amounts in the real fields.
  """
  @spec process_attrs(map, binary, binary, binary, binary | atom) :: map
  def process_attrs(attrs, key, virtual_field, field, currency) do
    case Map.get(attrs, key) do
      nil ->
        attrs

      items ->
        new_items =
          Map.new(
            Enum.map(items, fn {k, v} ->
              amount =
                v
                |> Map.get(virtual_field)
                |> get_amount(currency)

              {k, Map.put(v, field, "#{amount}")}
            end)
          )

        Map.put(attrs, key, new_items)
    end
  end

  @spec get_amount(nil | binary, binary | atom) :: integer
  defp get_amount(nil, _currency), do: 0

  defp get_amount(virtual_amount, currency) do
    case Money.parse(virtual_amount, currency) do
      {:ok, money} ->
        money.amount

      :error ->
        0
    end
  end

  @spec get_virtual_amount(integer, binary | atom) :: Decimal.t()
  defp get_virtual_amount(amount, currency) do
    amount
    |> Money.new(currency)
    |> Money.to_decimal()
  end
end

defmodule Siwapp.Invoices.AmountHelper do
  @moduledoc """
  Helper functions for Item and Payments schemas when handling with amounts
  """
  import Ecto.Changeset

  @doc """
  Given a virtual_field value it sets the field value to that.
  If the virtual_field is not set, then is set to the value of field.
  """
  @spec set_amount(Ecto.Changeset.t(), atom(), atom(), atom() | binary()) :: Ecto.Changeset.t()
  def set_amount(changeset, field, virtual_field, currency) do
    case get_field(changeset, virtual_field) do
      nil ->
        case get_field(changeset, field) do
          nil ->
            changeset

          amount ->
            virtual_amount =
              amount
              |> Money.new(currency)
              |> Money.to_decimal()

            put_change(changeset, virtual_field, virtual_amount)
        end

      "" ->
        put_change(changeset, field, 0)

      virtual_amount ->
        case Money.parse(virtual_amount, currency) do
          {:ok, money} ->
            changeset
            |> put_change(field, money.amount)
            |> put_change(virtual_field, Money.to_decimal(money))

          :error ->
            add_error(changeset, virtual_field, "Invalid format")
        end
    end
  end

  @doc """
  Given an invoice it sets the virtual amounts of the payments and items in order to show them
  correctly in the forms.
  """
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
  def process_attrs(attrs, key, virtual_field, field, currency) do
    case Map.get(attrs, key) do
      nil -> attrs
      items ->
        new_items =
          Enum.map(items, fn {k, v} ->
            amount =
              v
              |> Map.get(virtual_field)
              |> get_amount(currency)

            {k, Map.put(v, field, "#{amount}")}
          end)
          |> Map.new()

        Map.put(attrs, key, new_items)
    end
  end

  defp get_amount(virtual_amount, currency) do
    case Money.parse(virtual_amount, currency) do
      {:ok, money} ->
        money.amount

      :error ->
        0
    end
  end

  defp get_virtual_amount(amount, currency) do
    amount
    |> Money.new(currency)
    |> Money.to_decimal()
  end
end

defmodule Siwapp.Invoices.AmountHelper do
  @moduledoc """
  Helper functions for Item and Payments schemas when handling with amounts
  """
  import Ecto.Changeset

  @doc """
  Given the a virtual_field value it sets the field value to that.
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
end

defmodule Siwapp.InvoiceHelper do
  @moduledoc """
  Helper functions for Invoice and RecurringInvoice schemas
  """

  import Ecto.Changeset

  alias Siwapp.Customers
  alias Siwapp.Customers.Customer

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
  @spec calculate(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def calculate(changeset) do
    changeset
    |> set_net_amount()
    |> set_taxes_amounts()
    |> set_gross_amount()
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

  @spec set_net_amount(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp set_net_amount(changeset) do
    if is_nil(get_change(changeset, :items)) do
      changeset
    else
      total_net_amount =
        changeset
        |> get_field(:items)
        |> Enum.map(& &1.net_amount)
        |> Enum.sum()

      put_change(changeset, :net_amount, total_net_amount)
    end
  end

  @spec set_taxes_amounts(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp set_taxes_amounts(changeset) do
    if is_nil(get_change(changeset, :items)) do
      changeset
    else
      total_taxes_amounts =
        changeset
        |> get_field(:items)
        |> Enum.map(& &1.taxes_amount)
        |> Enum.reduce(%{}, &Map.merge(&1, &2, fn _, v1, v2 -> Decimal.add(v1, v2) end))
        |> Enum.map(fn {k, v} -> {k, v |> Decimal.round() |> Decimal.to_integer()} end)
        |> Map.new()

      put_change(changeset, :taxes_amounts, total_taxes_amounts)
    end
  end

  @spec set_gross_amount(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp set_gross_amount(changeset) do
    if is_nil(get_change(changeset, :items)) do
      changeset
    else
      taxes_amount =
        changeset
        |> get_field(:taxes_amounts)
        |> Map.values()
        |> Enum.sum()

      gross_amount = get_field(changeset, :net_amount) + taxes_amount

      put_change(changeset, :gross_amount, gross_amount)
    end
  end
end

defmodule Siwapp.RecurringInvoicesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Siwapp.RecurringInvoices` context.
  """

  alias Siwapp.Commons
  alias Siwapp.CustomersFixtures
  alias Siwapp.RecurringInvoices
  alias Siwapp.Repo

  @spec valid_recurring_invoice_attributes(map) :: map
  def valid_recurring_invoice_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: CustomersFixtures.unique_customer_name(),
      identification: CustomersFixtures.unique_customer_identification(),
      series_id: hd(Commons.list_series()).id,
      starting_date: Date.add(Date.utc_today(), -100),
      finishing_date: Date.utc_today(),
      period: 1,
      period_type: "Monthly",
      max_ocurrences: 10_000
    })
  end

  @spec recurring_invoice_fixture(map) :: RecurringInvoice.t()
  def recurring_invoice_fixture(attrs \\ %{}) do
    {:ok, recurring_invoice} =
      attrs
      |> valid_recurring_invoice_attributes()
      |> RecurringInvoices.create()

    Repo.preload(recurring_invoice, [:customer, :series])
  end
end

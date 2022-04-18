defmodule Siwapp.RecurringInvoicesTest do
  use Siwapp.DataCase

  import Siwapp.RecurringInvoicesFixtures
  import Siwapp.InvoicesFixtures
  import Siwapp.SettingsFixtures
  import Siwapp.CommonsFixtures

  alias Siwapp.RecurringInvoices

  setup do
    series_fixture(%{name: "A-Series", code: "A-"})
    taxes_fixture(%{name: "VAT", value: 21, default: true})
    taxes_fixture(%{name: "RETENTION", value: -15})
    today = Date.utc_today()
    settings_fixture()

    Cachex.clear(:siwapp_cache)

    %{today: today}
  end

  describe "invoices_to_generate/1 " do
    test "when period type is daily, it generates invoices every number of days the period indicates",
         %{today: today} do
      rec_invoice =
        recurring_invoice_fixture(%{
          starting_date: Date.add(today, -(30 * 12) * 2),
          finishing_date: today,
          period: 2,
          period_type: "Daily"
        })

      assert RecurringInvoices.invoices_to_generate(rec_invoice.id) == 30 * 12 + 1
    end

    test "when period type is monthly, it generates invoices every number of months the period indicates",
         %{today: today} do
      rec_invoice =
        recurring_invoice_fixture(%{
          starting_date: Date.add(today, -(30 * 12) * 2),
          finishing_date: today,
          period: 2,
          period_type: "Monthly"
        })

      assert RecurringInvoices.invoices_to_generate(rec_invoice.id) == 12
    end

    test "when period type is yearly, it generates invoices every number of years the period indicates",
         %{today: today} do
      rec_invoice =
        recurring_invoice_fixture(%{
          starting_date: Date.add(today, -(30 * 12) * 2),
          finishing_date: today,
          period: 2,
          period_type: "Yearly"
        })

      assert RecurringInvoices.invoices_to_generate(rec_invoice.id) == 1
    end

    test "the limit for generating invoices is the strictest boundary. Max ocurrences is the strictest.",
         %{today: today} do
      rec_invoice =
        recurring_invoice_fixture(%{
          max_ocurrences: 5,
          starting_date: Date.add(today, -20),
          finishing_date: Date.add(today, -10),
          period: 1,
          period_type: "Daily"
        })

      assert RecurringInvoices.invoices_to_generate(rec_invoice.id) == 5
    end

    test "the limit for generating invoices is the strictest boundary. Finishing date is the strictest.",
         %{today: today} do
      rec_invoice =
        recurring_invoice_fixture(%{
          max_ocurrences: 10,
          starting_date: Date.add(today, -10),
          finishing_date: Date.add(today, -6),
          period: 1,
          period_type: "Daily"
        })

      assert RecurringInvoices.invoices_to_generate(rec_invoice.id) == 5
    end

    test "the number of invoices to generate is calculated until the day of today", %{
      today: today
    } do
      rec_invoice =
        recurring_invoice_fixture(%{
          starting_date: Date.add(today, -4),
          finishing_date: Date.add(today, 5),
          period: 1,
          period_type: "Daily"
        })

      # If the day of today weren't in the middle, the result would be 10
      assert RecurringInvoices.invoices_to_generate(rec_invoice.id) == 5
    end

    test "if there are already generated invoices, they are substracted from the number of invoices to generate" do
      rec_invoice =
        recurring_invoice_fixture(%{max_ocurrences: 5, period: 1, period_type: "Daily"})

      invoice_fixture(recurring_invoice_id: rec_invoice.id)
      invoice_fixture(recurring_invoice_id: rec_invoice.id)
      invoice_fixture(recurring_invoice_id: rec_invoice.id)

      assert RecurringInvoices.invoices_to_generate(rec_invoice.id) == 5 - 3
    end
  end
end

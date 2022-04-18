defmodule Siwapp.Invoices.StatisticsTest do
  use Siwapp.DataCase

  import Siwapp.InvoicesFixtures
  import Siwapp.SettingsFixtures
  import Siwapp.CommonsFixtures

  alias Siwapp.Invoices.Statistics

  setup do
    series = series_fixture(%{name: "A-Series", code: "A-"})
    tax1 = taxes_fixture(%{name: "VAT", value: 21, default: true})
    tax2 = taxes_fixture(%{name: "RETENTION", value: -15})
    settings_fixture()

    Cachex.clear(:siwapp_cache)

    %{series_id: series.id, taxes: [tax1, tax2], today: Date.utc_today()}
  end

  describe "get_amount_per_day/1" do
    test "when there is no invoices it returns a month of 0 values", %{today: today} do
      month = Date.range(Date.add(today, -30), today)
      assert Statistics.get_amount_per_day() == Enum.map(month, &{&1, 0})
    end

    test "for multiple invoices in different days, it returns one value for each one with its amount",
         %{today: today} do
      invoice_fixture(%{
        issue_date: today,
        items: [valid_item_attributes(%{unitary_cost: 500, discount: 0, taxes: []})]
      })

      yesterday = Date.add(today, -1)

      invoice_fixture(%{
        issue_date: yesterday,
        items: [valid_item_attributes(%{unitary_cost: 500, discount: 0, taxes: []})]
      })

      assert Enum.member?(Statistics.get_amount_per_day(), {today, 500}) and
               Enum.member?(Statistics.get_amount_per_day(), {yesterday, 500})
    end

    test "for multiple invoices in the same day, it returns one unique value with the sum of its amounts",
         %{today: today} do
      invoice_fixture(%{
        issue_date: today,
        items: [valid_item_attributes(%{unitary_cost: 500, discount: 0, taxes: []})]
      })

      invoice_fixture(%{
        issue_date: today,
        items: [valid_item_attributes(%{unitary_cost: 500, discount: 0, taxes: []})]
      })

      assert Enum.member?(Statistics.get_amount_per_day(), {today, 1000})
    end
  end

  describe "get_amount_per_currencies/1" do
    test "when there is no invoices it returns a tuple with an empty map and 0" do
      assert Statistics.get_amount_per_currencies_and_count(:gross) == {%{}, 0}
    end

    test "for multiple invoices with different currencies, there is a key and an amount for each one" do
      invoice_fixture(%{
        items: [valid_item_attributes(%{unitary_cost: 500, discount: 0, taxes: []})],
        currency: "USD"
      })

      invoice_fixture(%{
        items: [valid_item_attributes(%{unitary_cost: 500, discount: 0, taxes: []})],
        currency: "GBP"
      })

      assert Statistics.get_amount_per_currencies_and_count(:gross) ==
               {%{"USD" => 500, "GBP" => 500}, Decimal.new(2)}
    end

    test "for multiple invoices with the same currency, there is only one key and accumulated amount for them" do
      invoice_fixture(%{
        items: [valid_item_attributes(%{unitary_cost: 500, discount: 0, taxes: []})],
        currency: "USD"
      })

      invoice_fixture(%{
        items: [valid_item_attributes(%{unitary_cost: 500, discount: 0, taxes: []})],
        currency: "USD"
      })

      assert Statistics.get_amount_per_currencies_and_count(:gross) ==
               {%{"USD" => 1000}, Decimal.new(2)}
    end
  end
end

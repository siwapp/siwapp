defmodule Siwapp.CustomersTest do
  use Siwapp.DataCase

  import Siwapp.CustomersFixtures
  import Siwapp.InvoicesFixtures
  import Siwapp.SettingsFixtures
  import Siwapp.CommonsFixtures
  alias Siwapp.Customers

  setup do
    series = series_fixture(%{name: "A-Series", code: "A-"})
    tax1 = taxes_fixture(%{name: "VAT", value: 21, default: true})
    tax2 = taxes_fixture(%{name: "RETENTION", value: -15})
    settings_fixture()

    Cachex.clear(:siwapp_cache)

    %{series_id: series.id, taxes: [tax1, tax2], today: Date.utc_today()}
  end

  describe "create_customer/1" do
    test "requires name or identification to be set" do
      {:error, changeset} = Customers.create(%{})

      assert %{
               name: ["Either name or identification are required"]
             } = errors_on(changeset)
    end

    test "validates identification uniqueness" do
      %{name: name, identification: identification} = customer_fixture()
      {:error, changeset} = Customers.create(%{name: name, identification: identification})
      assert "has already been taken" in errors_on(changeset).identification

      # Now try with the upper cased email too, to check that name case is ignored.
      {:error, changeset} =
        Customers.create(%{name: String.upcase(name), identification: identification})

      assert "has already been taken" in errors_on(changeset).identification
    end

    test "validates hash_id uniqueness" do
      %{name: name, identification: identification} = customer_fixture(%{identification: nil})
      {:error, changeset} = Customers.create(%{name: name, identification: identification})
      assert "has already been taken" in errors_on(changeset).hash_id

      # Now try with the upper cased email too, to check that name case is ignored.
      {:error, changeset} =
        Customers.create(%{name: String.upcase(name), identification: identification})

      assert "has already been taken" in errors_on(changeset).hash_id
    end
  end

  describe "list_with_assoc_invoice_fields/1" do
    test "for a customer with no invoices, its total is 0" do
      assert customer_with_totals(customer_fixture().id).total == 0
    end

    test "for a customer with no invoices, its paid is 0" do
      assert customer_with_totals(customer_fixture().id).paid == 0
    end

    test "for a customer with one invoice, its total is the invoice's total" do
      customer = customer_fixture()

      invoice_fixture(%{
        name: customer.name,
        identification: customer.identification,
        items: [%{unitary_cost: 200}]
      })

      assert customer_with_totals(customer.id).total == 200
    end

    test "for a customer with one invoice, its paid is the invoice's paid" do
      customer = customer_fixture()

      invoice_fixture(%{
        name: customer.name,
        identification: customer.identification,
        items: [%{unitary_cost: 200}],
        payments: [%{amount: 200}]
      })

      assert customer_with_totals(customer.id).paid == 200
    end

    test "for a customer with multiple invoices, its total is the sum of invoices' total" do
      customer = customer_fixture()

      invoice_fixture(%{
        name: customer.name,
        identification: customer.identification,
        items: [%{unitary_cost: 200}]
      })

      invoice_fixture(%{
        name: customer.name,
        identification: customer.identification,
        items: [%{unitary_cost: 200}]
      })

      assert customer_with_totals(customer.id).total == 400
    end

    test "for a customer with multiple invoices, its paid is the sum of the invoices' paid" do
      customer = customer_fixture()

      invoice_fixture(%{
        name: customer.name,
        identification: customer.identification,
        items: [%{unitary_cost: 200}],
        payments: [%{amount: 200}]
      })

      invoice_fixture(%{
        name: customer.name,
        identification: customer.identification,
        items: [%{unitary_cost: 200}],
        payments: [%{amount: 200}]
      })

      assert customer_with_totals(customer.id).paid == 400
    end
  end
end

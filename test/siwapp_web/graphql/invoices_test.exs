defmodule SiwappWeb.Graphql.InvoicesTest do
  use SiwappWeb.ConnCase, async: true

  import Siwapp.InvoicesFixtures
  import Siwapp.CommonsFixtures
  import Siwapp.SettingsFixtures

  setup do
    Cachex.clear(:siwapp_cache)
    series = series_fixture(%{name: "A-Series", code: "A-"})
    taxes_fixture(%{name: "VAT", value: 21, default: true})
    taxes_fixture(%{name: "RETENTION", value: -15})
    settings_fixture()

    invoices =
      Enum.map(1..11, fn _i ->
        invoice_fixture(%{name: "test_name", identification: "test_id"})
      end)

    %{invoices: invoices, series: series}
  end

  test "list invoices by a customer_id and get its name", %{conn: conn, invoices: invoices} do
    invoice = hd(invoices)

    query = """
      query {
        invoices(customer_id: #{invoice.customer_id} ) {
          name
          customer_id
        }
      }
    """

    data_result =
      Enum.map(1..10, fn _i ->
        %{"name" => invoice.name, "customer_id" => "#{invoice.customer_id}"}
      end)

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert res == %{"data" => %{"invoices" => data_result}}
  end

  test "Get an invoice", %{conn: conn, invoices: invoices} do
    invoice = hd(invoices)

    query = """
      query {
        invoice(id: #{invoice.id}) {
          name
        }
      }
    """

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert res == %{"data" => %{"invoice" => %{"name" => invoice.name}}}
  end

  test "Create an invoice", %{conn: conn, series: series} do
    query = """
      mutation {
        create_invoice(name: "test_name", series_code: "#{series.code}", metaAttributes: [{key: "testkey"}]) {
          name
          series_id
          metaAttributes {
            key
            value
          }
        }
      }
    """

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert res == %{
             "data" => %{
               "create_invoice" => %{
                 "name" => "test_name",
                 "series_id" => "#{series.id}",
                 "metaAttributes" => [
                   %{"key" => "testkey", "value" => nil}
                 ]
               }
             }
           }
  end

  test "Update an invoice", %{conn: conn, invoices: invoices} do
    invoice = hd(invoices)

    query = """
    mutation {
      update_invoice(id: #{invoice.id}, email: "info@example.com", metaAttributes: [{key: "testkey" value: "testvalue"}]) {
        name
        email
        metaAttributes {
          key
          value
        }
        }
      }
    """

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert res == %{
             "data" => %{
               "update_invoice" => %{
                 "name" => invoice.name,
                 "email" => "info@example.com",
                 "metaAttributes" => [
                   %{"key" => "testkey", "value" => "testvalue"}
                 ]
               }
             }
           }
  end

  test "Updating an invoice with a value but not with a key inside meta_attributes will return an error",
       %{conn: conn, invoices: invoices} do
    invoice = hd(invoices)

    query = """
    mutation {
      update_invoice(id: #{invoice.id}, metaAttributes: [{value: "testvalue"}]) {
        metaAttributes {
          key
          value
        }
      }
    }
    """

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    error_map = hd(res["errors"])

    assert res == %{"errors" => [error_map]}
  end

  test "Delete an invoice", %{conn: conn, invoices: invoices} do
    invoice = hd(invoices)

    query = """
      mutation {
        delete_invoice(id: #{invoice.id}) {
          name
        }
      }
    """

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert res == %{"data" => %{"delete_invoice" => %{"name" => invoice.name}}}
  end
end

defmodule SiwappWeb.Graphql.CustomersTest do
  use SiwappWeb.ConnCase, async: true

  import Siwapp.CustomersFixtures

  setup do
    customer = customer_fixture(%{name: "test_name", identification: "test_id"})

    %{customer: customer}
  end

  test "list customers using default options", %{conn: conn} do
    query = """
      query {
        customers {
          name
          identification
        }
      }
    """

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert res == %{
             "data" => %{
               "customers" => [%{"name" => "test_name", "identification" => "test_id"}]
             }
           }
  end

  test "create a customer", %{conn: conn} do
    query = """
      mutation {
        create_customer(name: "test_name2", identification: "test_id2") {
          name
          identification
        }
      }
    """

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert res == %{
             "data" => %{
               "create_customer" => %{"name" => "test_name2", "identification" => "test_id2"}
             }
           }
  end

  test "delete a customer", %{conn: conn, customer: customer} do
    query = """
      mutation {
        delete_customer(id: #{customer.id}) {
          name
        }
      }
    """

    res =
      conn
      |> post("/graphql", %{query: query})
      |> json_response(200)

    assert res == %{
             "data" => %{
               "delete_customer" => %{"name" => "test_name"}
             }
           }
  end
end

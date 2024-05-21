defmodule SiwappWeb.PageController do
  use SiwappWeb, :controller
  alias Siwapp.Customers.Customer
  alias Siwapp.Invoices
  alias Siwapp.Invoices.Invoice
  alias Siwapp.Query
  alias Siwapp.RecurringInvoices.RecurringInvoice
  alias Siwapp.Repo
  alias Siwapp.Searches
  alias Siwapp.Templates

  @spec show_invoice(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show_invoice(conn, %{"id" => id} = params) do
    invoice =
      id
      |> String.to_integer()
      |> Invoices.get!()

    conn
    |> assign(:invoice, invoice)
    |> assign(:url_query_string, Map.delete(params, "id"))
    |> render("show_invoice.html")
  end

  @spec download(Plug.Conn.t(), map) :: Plug.Conn.t()
  def download(conn, %{"id" => id}) do
    invoice = Invoices.get!(id)
    {pdf_content, pdf_name} = Templates.pdf_content_and_name(invoice)

    send_download(conn, {:binary, pdf_content}, filename: pdf_name)
  end

  def download(conn, %{"ids" => ids}) do
    {pdf_content, pdf_name} =
      ids
      |> Enum.map(&Invoices.get!/1)
      |> Templates.pdf_content_and_name()

    send_download(conn, {:binary, pdf_content}, filename: pdf_name)
  end

  @spec send_email(Plug.Conn.t(), map) :: Plug.Conn.t()
  def send_email(conn, %{"id" => id}) do
    id
    |> Invoices.get!()
    |> Invoices.send_email()
    |> case do
      {:ok, _id} -> put_flash(conn, :info, "Email successfully sent")
      {:error, msg} -> put_flash(conn, :error, msg)
    end
    |> redirect(to: "/invoices/#{id}/show")
  end

  @spec csv(Plug.Conn.t(), map) :: Plug.Conn.t()
  def csv(conn, params) do
    queryable = which_queryable(params["view"])

    keys =
      [:id]
      |> Kernel.++(queryable.fields)
      |> Kernel.--([:meta_attributes])
      |> Kernel.++([:inserted_at, :updated_at])
      |> maybe_add_series_code_key(params["view"])
      |> maybe_add_reference_key(params["view"])
      |> maybe_delete_key(params["view"])
      |> maybe_add_meta_attributes_key(params)

    query_params =
      params
      |> Map.delete("view")
      |> Enum.reject(fn {_key, val} -> val == "" end)

    conn =
      conn
      |> put_resp_content_type("application/csv")
      |> put_resp_header("content-disposition", "attachment; filename=#{params["view"]}s.csv")
      |> send_chunked(200)

    queryable
    |> get_stream_from_a_queryable(query_params, keys)
    |> CSV.encode()
    |> Enum.reduce_while(conn, fn chunk, conn ->
      case chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, conn}

        {:error, :closed} ->
          {:halt, conn}
      end
    end)
  end

  @spec which_queryable(binary) :: Ecto.Queryable.t()
  defp which_queryable(view) do
    case view do
      "invoice" ->
        Invoice

      "customer" ->
        Customer

      "recurring_invoice" ->
        RecurringInvoice
    end
  end

  @spec maybe_delete_key([atom], binary) :: [atom]
  defp maybe_delete_key(keys, view) do
    if view == "recurring_invoice" do
      keys -- [:items]
    else
      keys
    end
  end

  @spec maybe_add_series_code_key([atom], binary) :: [atom]
  defp maybe_add_series_code_key(keys, "invoice"), do: keys ++ [:series_code]
  defp maybe_add_series_code_key(keys, _else), do: keys

  @spec maybe_add_reference_key([atom], binary) :: [atom]
  defp maybe_add_reference_key(keys, "invoice"), do: keys ++ [:reference]
  defp maybe_add_reference_key(keys, _else), do: keys

  @spec maybe_add_meta_attributes_key([atom], map) :: [atom]
  defp maybe_add_meta_attributes_key(keys, %{"csv_meta_attributes" => meta_attributes_params}) do
    keys ++
      Enum.map(meta_attributes_params, fn {_key, %{"key" => key}} -> String.to_atom(key) end)
  end

  defp maybe_add_meta_attributes_key(keys, _else), do: keys

  # Stream of the keys plus values from every invoice, recurring_invoice or customer a user decide to filter
  @spec get_stream_from_a_queryable(Ecto.Queryable.t(), [{binary, binary}], [atom]) ::
          Enumerable.t()
  defp get_stream_from_a_queryable(queryable, query_params, fields) do
    [fields]
    |> Kernel.++(values(queryable, query_params, fields))
    |> Stream.map(& &1)
  end

  # Values from every invoice, recurring_invoice or customer a user decide to filter
  @spec values(Ecto.Queryable.t(), [{binary, binary}], [atom]) :: [list()]
  defp values(queryable, query_params, fields) do
    params = Map.new(query_params)

    queryable
    |> Searches.filters_query(query_params)
    |> maybe_deleted_at_query(queryable)
    |> Repo.all()
    |> maybe_preload_series(queryable)
    |> Enum.map(&prepare_values(&1, fields, params))
  end

  @spec maybe_deleted_at_query(Ecto.Query.t(), Ecto.Queryable.t()) :: Ecto.Query.t()
  defp maybe_deleted_at_query(query, queryable) do
    if queryable == Invoice do
      Query.not_deleted(query)
    else
      query
    end
  end

  @spec maybe_preload_series(list, Ecto.Queryable.t()) :: list
  defp maybe_preload_series(invoices, Invoice), do: Repo.preload(invoices, :series)
  defp maybe_preload_series(others, _else), do: others

  # For each invoice, customer or recurring_invoice gets its own sorted values
  @spec prepare_values(Ecto.Queryable.t(), [atom], map) :: list()
  defp prepare_values(struct, fields, params) do
    struct
    |> maybe_add_series_code()
    |> maybe_add_reference()
    |> maybe_add_meta_attributes(params)
    |> sort_values(fields)
  end

  @spec maybe_add_series_code(Ecto.Queryable.t()) :: map()
  defp maybe_add_series_code(%Invoice{series: %{code: code}} = invoice),
    do: Map.put(invoice, :series_code, code)

  defp maybe_add_series_code(other), do: other

  @spec maybe_add_reference(Ecto.Queryable.t()) :: map
  defp maybe_add_reference(%Invoice{series: %{code: code}, number: number} = invoice),
    do: Map.put(invoice, :reference, "#{code}-#{number}")

  defp maybe_add_reference(other), do: other

  @spec maybe_add_meta_attributes(map, map) :: map()
  defp maybe_add_meta_attributes(%{meta_attributes: meta_attributes} = record, %{
         "csv_meta_attributes" => meta_attributes_params
       }) do
    Enum.reduce(meta_attributes_params, record, fn {_index, %{"key" => key}}, acc ->
      meta_attribute = Map.get(meta_attributes, key)
      Map.put(acc, String.to_atom(key), meta_attribute)
    end)
  end

  defp maybe_add_meta_attributes(record, _else), do: record

  @spec sort_values(map, list) :: list
  defp sort_values(map, fields) do
    Enum.reduce(fields, [], fn key, acc -> acc ++ [Map.get(map, key)] end)
  end
end

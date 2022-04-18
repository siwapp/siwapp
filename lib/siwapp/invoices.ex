defmodule Siwapp.Invoices do
  @moduledoc """
  The Invoices context.
  """
  import Ecto.Query, warn: false

  alias Siwapp.InvoiceHelper
  alias Siwapp.Invoices.Invoice
  alias Siwapp.Invoices.InvoiceQuery
  alias Siwapp.Invoices.Item
  alias Siwapp.Invoices.Payment
  alias Siwapp.Query
  alias Siwapp.Repo

  @doc """
  Gets a list of invoices by updated date with the parameters included in the options
  """
  @spec list(keyword()) :: [Invoice.t()]
  def list(options \\ []) do
    default = [limit: 100, offset: 0, preload: [], filters: [], order_by: [desc: :id]]
    options = Keyword.merge(default, options)

    options[:filters]
    |> Enum.reduce(Invoice, fn {field, value}, acc_query ->
      InvoiceQuery.list_by_query(acc_query, field, value)
    end)
    |> Query.not_deleted()
    |> limit(^options[:limit])
    |> offset(^options[:offset])
    |> order_by(^options[:order_by])
    |> Query.list_preload(options[:preload])
    |> Repo.all()
  end

  @doc """
  Creates an invoice
  """

  @spec create(map()) :: {:ok, Invoice.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs \\ %{}) do
    %Invoice{}
    |> change(attrs)
    |> InvoiceHelper.maybe_find_customer_or_new()
    |> Invoice.assign_number()
    |> Repo.insert()
  end

  @doc """
  Update an invoice
  """

  @spec update(Invoice.t(), map()) :: {:ok, Invoice.t()} | {:error, Ecto.Changeset.t()}
  def update(%Invoice{} = invoice, attrs) do
    invoice
    |> change(attrs)
    |> InvoiceHelper.maybe_find_customer_or_new()
    |> Invoice.assign_number()
    |> Repo.update()
  end

  @doc """
  Delete an invoice
  """

  @spec delete(Invoice.t()) :: {:ok, Invoice.t()} | {:error, Ecto.Changeset.t()}
  def delete(%Invoice{} = invoice) do
    __MODULE__.update(invoice, %{deleted_at: DateTime.utc_now()})
  end

  @doc """
  Adds virtual fields to invoice struct
  """
  @spec with_virtual_fields(Invoice.t()) :: Invoice.t()
  def with_virtual_fields(invoice) do
    items_with_calculations =
      Enum.map(invoice.items, &Ecto.Changeset.apply_changes(change_item(&1, invoice.currency)))

    invoice = Map.put(invoice, :items, items_with_calculations)
    changeset = change(invoice)
    Ecto.Changeset.apply_changes(changeset)
  end

  @doc """
  Sends email with email_default template as email_body, attaching
  pdf made with print_default template using invoice data and if
  operation successes, updates invoice sent_by_email field to true
  """
  @spec send_email(Invoice.t()) :: {:ok, pos_integer} | {:error, binary}
  def send_email(invoice) do
    case Siwapp.InvoiceMailer.build_invoice_email(invoice) do
      {:error, msg} ->
        {:error, msg}

      {:ok, email} ->
        case Siwapp.Mailer.deliver(email, mailer_options(System.get_env("MAILER"))) do
          {:ok, id} ->
            __MODULE__.update(invoice, %{sent_by_email: true})
            {:ok, id}

          {:error, msg} ->
            {:error, msg}
        end
    end
  end

  @spec mailer_options(nil | binary) :: [] | [adapter: atom]
  defp mailer_options(nil), do: []
  defp mailer_options(mailer), do: [adapter: String.to_atom("Elixir.Swoosh.Adapters.#{mailer}")]

  @spec set_paid(Invoice.t()) :: {:ok, Invoice.t()} | {:error, Ecto.Changeset.t()}
  def set_paid(invoice) do
    final_payments = invoice.payments ++ [last_payment(invoice)]
    payments_attrs = Enum.map(final_payments, &Map.take(&1, [:amount, :date, :notes, :id]))

    __MODULE__.update(invoice, %{payments: payments_attrs})
  end

  @spec get(pos_integer()) :: Invoice.t() | nil
  def get(id) do
    Invoice
    |> Query.not_deleted()
    |> Repo.get(id)
  end

  @spec get(pos_integer(), keyword()) :: Invoice.t() | nil
  def get(id, preload: list) do
    Invoice
    |> Query.not_deleted()
    |> Repo.get(id)
    |> Repo.preload(list)
  end

  @doc """
  Gets an invoice by id
  """

  @spec get!(pos_integer() | binary()) :: Invoice.t()
  def get!(id) do
    Invoice
    |> Query.not_deleted()
    |> Repo.get!(id)
  end

  @spec get!(pos_integer(), keyword()) :: Invoice.t()
  def get!(id, preload: list) do
    Invoice
    |> Query.not_deleted()
    |> Repo.get!(id)
    |> Repo.preload(list)
  end

  @doc """
  Get a single invoice by the params
  """

  @spec get_by!(atom(), any()) :: Invoice.t()
  def get_by!(key, value) do
    Invoice
    |> Query.not_deleted()
    |> Repo.get_by!(%{key => value})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invoice changes.
  """
  @spec change(Invoice.t(), map) :: Ecto.Changeset.t()
  def change(%Invoice{} = invoice, attrs \\ %{}) do
    Invoice.changeset(invoice, attrs)
  end

  @spec status(Invoice.t()) :: :draft | :failed | :paid | :pending | :past_due
  def status(invoice) do
    cond do
      invoice.draft -> :draft
      invoice.failed -> :failed
      invoice.paid -> :paid
      !is_nil(invoice.due_date) -> due_date_status(invoice.due_date)
      true -> :pending
    end
  end

  @spec list_currencies :: [atom]
  def list_currencies do
    Money.Currency.all()
    |> Map.keys()
    |> Enum.sort()
  end

  @spec due_date_status(DateTime.t()) :: :pendig | :past_due
  defp due_date_status(due_date) do
    if Date.diff(due_date, Date.utc_today()) >= 0 do
      :pending
    else
      :past_due
    end
  end

  @doc """
  Gets an item by id
  """
  @spec get_item_by_id!(pos_integer()) :: Item.t()
  def get_item_by_id!(id), do: Repo.get!(Item, id)

  @doc """
  Creates an item associated to an invoice
  """
  @spec create_item(Invoice.t(), atom() | binary(), map()) ::
          {:ok, Item.t()} | {:error, Ecto.Changeset.t()}
  def create_item(%Invoice{} = invoice, currency, attrs \\ %{}) do
    invoice
    |> Ecto.build_assoc(:items)
    |> Item.changeset(attrs, currency)
    |> Repo.insert()
  end

  @doc """
  Updates an item
  """
  @spec update_item(Item.t(), atom() | binary(), map()) ::
          {:ok, Item.t()} | {:error, Ecto.Changeset.t()}
  def update_item(%Item{} = item, currency, attrs) do
    item
    |> Repo.preload(:taxes)
    |> Item.changeset(attrs, currency)
    |> Repo.update()
  end

  @doc """
  Deletes an item
  """
  @spec delete_item(Item.t()) :: {:ok, Item.t()} | {:error, Ecto.Changeset.t()}
  def delete_item(%Item{} = item), do: Repo.delete(item)

  @doc """
  Change an item
  """
  @spec change_item(Item.t(), binary | atom, map) :: Ecto.Changeset.t()
  def change_item(%Item{} = item, currency, attrs \\ %{}) do
    Item.changeset(item, attrs, currency)
  end

  @doc """
  Gets a payment by id
  """
  @spec get_payment_by_id!(pos_integer()) :: Payment.t()
  def get_payment_by_id!(id), do: Repo.get!(Payment, id)

  @doc """
  Creates a payment associated to an invoice
  """
  @spec create_payment(Invoice.t(), atom() | binary(), map()) ::
          {:ok, Payment.t()} | {:error, Ecto.Changeset.t()}
  def create_payment(%Invoice{} = invoice, currency, attrs \\ %{}) do
    invoice
    |> Ecto.build_assoc(:payments)
    |> Payment.changeset(attrs, currency)
    |> Repo.insert()
  end

  @doc """
  Updates a payment
  """
  @spec update_payment(Payment.t(), atom() | binary(), map()) ::
          {:ok, Payment.t()} | {:error, Ecto.Changeset.t()}
  def update_payment(%Payment{} = payment, currency, attrs) do
    payment
    |> Payment.changeset(attrs, currency)
    |> Repo.update()
  end

  @doc """
  Deletes a payment
  """
  @spec delete_payment(Payment.t()) :: {:ok, Payment.t()} | {:error, Ecto.Changeset.t()}
  def delete_payment(%Payment{} = payment), do: Repo.delete(payment)

  @doc """
  Change a payment
  """
  @spec change_payment(Payment.t(), atom() | binary(), map) :: Ecto.Changeset.t()
  def change_payment(%Payment{} = payment, currency, attrs \\ %{}) do
    Payment.changeset(payment, attrs, currency)
  end

  @spec duplicate(Invoice.t()) :: Ecto.Changeset.t()
  def duplicate(invoice) do
    params_keys =
      Invoice.fields() -- [:paid_amount, :paid, :sent_by_email, :number, :recurring_invoice_id]

    new_items_attrs = Enum.map(invoice.items, &take_items_attrs(&1))

    attrs =
      invoice
      |> Map.take(params_keys)
      |> Map.put(:items, new_items_attrs)

    change(%Invoice{}, attrs)
  end

  @spec take_items_attrs(Item.t()) :: map()
  defp take_items_attrs(item) do
    items_keys = [
      :description,
      :discount,
      :quantity,
      :unitary_cost,
      :taxes
    ]

    item
    |> Map.take(items_keys)
    |> Map.put(:taxes, Enum.map(item.taxes, & &1.name))
  end

  @spec last_payment(Invoice.t()) :: map()
  defp last_payment(invoice) do
    %Payment{
      amount: invoice.gross_amount - invoice.paid_amount,
      date: Date.utc_today()
    }
  end
end

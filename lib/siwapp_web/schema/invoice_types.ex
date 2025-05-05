defmodule SiwappWeb.Schema.InvoiceTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias SiwappWeb.Resolvers.Invoice

  object :invoice do
    field :id, :id
    field :customer_id, :id
    field :customer, :customer
    field :name, :string
    field :identification, :string
    field :contact_person, :string
    field :email, :string
    field :invoicing_address, :string
    field :shipping_address, :string
    field :terms, :string
    field :notes, :string
    field :series_id, :id
    field :series_code, :string, resolve: &Invoice.get_series_code/3
    field :number, :string
    field :reference, :string
    field :currency, :string
    field :issue_date, :date
    field :due_date, :date
    field :draft, :boolean
    field :status, :string
    field :items, list_of(:item)
    field :payments, list_of(:payment)

    field :gross_amount, :string do
      arg(:format, :string)
      resolve(&Invoice.format_amount(:gross_amount, &1, &2, &3))
    end

    field :net_amount, :string do
      arg(:format, :string)
      resolve(&Invoice.format_amount(:net_amount, &1, &2, &3))
    end

    field :paid_amount, :string do
      arg(:format, :string)
      resolve(&Invoice.format_amount(:paid_amount, &1, &2, &3))
    end

    field :paid, :boolean
    field :failed, :boolean
    field :recurring_invoice_id, :id
    field :sent_by_email, :boolean
    field :inserted_at, :date
    field :updated_at, :date

    field :meta_attributes, list_of(:meta_attribute) do
      resolve(fn invoice, _, _ ->
        {:ok, Map.to_list(invoice.meta_attributes)}
      end)
    end
  end
end

defmodule SiwappWeb.Schema.InvoiceTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :invoice do
    field :id, :id
    field :customer_id, :id
    field :name, :string
    field :identification, :string
    field :contact_person, :string
    field :email, :string
    field :invoicing_address, :string
    field :shipping_address, :string
    field :terms, :string
    field :notes, :string
    field :series_id, :id
    field :number, :string
    field :currency, :string
    field :issue_date, :date
    field :due_date, :date
    field :draft, :boolean
    field :items, list_of(:item)
    field :payments, list_of(:payment)
    field :gross_amount, :string
    field :net_amount, :string
    field :paid_amount, :string
    field :paid, :boolean
    field :failed, :boolean
    field :recurring_invoice, :id
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

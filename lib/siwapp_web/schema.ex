defmodule SiwappWeb.Schema do
  @moduledoc false

  use Absinthe.Schema

  import SiwappWeb.Schema.Helpers

  import_types(SiwappWeb.Schema.CustomerTypes)
  import_types(SiwappWeb.Schema.InvoiceTypes)
  import_types(SiwappWeb.Schema.ItemTypes)
  import_types(SiwappWeb.Schema.PaymentTypes)
  import_types(SiwappWeb.Schema.MetaAttributeTypes)
  import_types(Absinthe.Type.Custom)

  alias SiwappWeb.Resolvers

  query do
    @desc "Get all customers"
    field :customers, list_of(:customer) do
      arg(:limit, :integer, default_value: 10)
      arg(:offset, :integer, default_value: 0)

      resolve(&Resolvers.Customer.list/2)
    end

    @desc "Get an invoice"
    field :invoice, :invoice do
      arg(:id, non_null(:id))

      resolve(&Resolvers.Invoice.get/2)
    end

    @desc "Get all invoices"
    field :invoices, list_of(:invoice) do
      arg(:customer_id, :id)
      arg(:limit, :integer, default_value: 10)
      arg(:offset, :integer, default_value: 0)

      resolve(&Resolvers.Invoice.list/2)
    end
  end

  input_object :items do
    field :id, :id
    field :quantity, :integer
    field :discount, :integer
    field :description, :string
    field :unitary_cost, :integer
    field :taxes, list_of(:string)
  end

  input_object :payments do
    field :id, :id
    field :amount, :integer
    field :date, :date
    field :notes, :string
  end

  input_object :meta_attributes do
    field :key, type: non_null(:string)
    field :value, :string
  end

  mutation do
    @desc "Create a customer"
    field :create_customer, type: :customer do
      arg(:name, non_null(:string))
      arg(:identification, :string)
      arg(:email, :string)
      arg(:contact_person, :string)
      arg(:invoicing_address, :string)
      arg(:shipping_address, :string)
      arg(:meta_attributes, list_of(:meta_attributes))

      resolve(&Resolvers.Customer.create/2)
    end

    @desc "Delete a customer"
    field :delete_customer, type: :customer do
      arg(:id, non_null(:integer))

      resolve(&Resolvers.Customer.delete/2)
    end

    @desc "Create an invoice"
    field :create_invoice, type: :invoice do
      invoice_args()

      resolve(&Resolvers.Invoice.create/2)
    end

    @desc "Update an invoice"
    field :update_invoice, type: :invoice do
      arg(:id, non_null(:integer))
      invoice_args()

      resolve(&Resolvers.Invoice.update/2)
    end

    @desc "Delete an invoice"
    field :delete_invoice, type: :invoice do
      arg(:id, non_null(:integer))

      resolve(&Resolvers.Invoice.delete/2)
    end
  end
end

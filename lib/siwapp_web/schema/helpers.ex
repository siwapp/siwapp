defmodule SiwappWeb.Schema.Helpers do
  @moduledoc """
  Helpers to use in GraphQL mutations.
  """

  defmacro invoice_args do
    quote do
      arg(:name, :string)
      arg(:identification, :string)
      arg(:email, :string)
      arg(:contact_person, :string)
      arg(:invoicing_address, :string)
      arg(:shipping_address, :string)
      arg(:terms, :string)
      arg(:notes, :string)
      arg(:series_code, :string)
      arg(:currency, :string)
      arg(:issue_date, :date)
      arg(:due_date, :date)
      arg(:draft, :boolean)
      arg(:items, list_of(:items))
      arg(:payments, list_of(:payments))
      arg(:failed, :boolean)
      arg(:meta_attributes, list_of(:meta_attributes))
    end
  end
end

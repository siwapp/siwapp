defmodule SiwappWeb.Schema.CustomerTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :customer do
    field :id, :id
    field :identification, :string
    field :name, :string
    field :email, :string
    field :contact_person, :string
    field :invoicing_address, :string
    field :shipping_address, :string

    field :meta_attributes, list_of(:meta_attribute) do
      resolve(fn customer, _, _ ->
        {:ok, Map.to_list(customer.meta_attributes)}
      end)
    end
  end
end

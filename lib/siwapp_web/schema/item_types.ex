defmodule SiwappWeb.Schema.ItemTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :tax do
    field :value, :integer
    field :id, :integer
  end

  object :item do
    field :id, :id
    field :quantity, :integer
    field :discount, :integer
    field :description, :string
    field :unitary_cost, :string
    field :invoice, :invoice
    field :taxes, list_of(:tax)
  end
end

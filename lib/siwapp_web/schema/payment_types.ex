defmodule SiwappWeb.Schema.PaymentTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :payment do
    field :amount, :integer
    field :date, :date
    field :id, :id
    field :notes, :string
    field :invoice, :invoice
  end
end

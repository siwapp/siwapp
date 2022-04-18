defmodule Siwapp.Invoices.Payment do
  @moduledoc """
  Payment
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Siwapp.Invoices.AmountHelper
  alias Siwapp.Invoices.Invoice

  @fields [
    :date,
    :amount,
    :notes,
    :invoice_id,
    :virtual_amount
  ]

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          amount: non_neg_integer(),
          notes: binary() | nil,
          updated_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil,
          invoice_id: pos_integer() | nil,
          virtual_amount: float() | nil
        }

  schema "payments" do
    field :date, :date
    field :amount, :integer, default: 0
    field :notes, :string
    field :virtual_amount, :decimal, virtual: true
    belongs_to :invoice, Invoice

    timestamps()
  end

  @spec changeset(t(), map, atom() | binary()) :: Ecto.Changeset.t()
  def changeset(payment, attrs \\ %{}, currency) do
    payment
    |> cast(attrs, @fields)
    |> assign_date()
    |> set_amount(:amount, :virtual_amount, currency)
    |> foreign_key_constraint(:invoice_id)
  end

  @spec assign_date(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp assign_date(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      put_change(changeset, :date, Date.utc_today())
    end
  end
end

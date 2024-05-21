defmodule Siwapp.RecurringInvoices.RecurringInvoice do
  @moduledoc """
  Recurring Invoice
  """

  use Ecto.Schema

  import Ecto.Changeset
  import Siwapp.InvoiceHelper

  alias Siwapp.Commons.Series
  alias Siwapp.Customers.Customer
  alias Siwapp.Invoices.Invoice
  alias Siwapp.Invoices.Item

  @fields [
    :name,
    :identification,
    :email,
    :contact_person,
    :invoicing_address,
    :shipping_address,
    :net_amount,
    :gross_amount,
    :send_by_email,
    :days_to_due,
    :enabled,
    :max_ocurrences,
    :period,
    :period_type,
    :starting_date,
    :finishing_date,
    :currency,
    :notes,
    :terms,
    :meta_attributes,
    :customer_id,
    :series_id
  ]

  @email_regex Application.compile_env!(:siwapp, :email_regex)

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: nil | pos_integer(),
          enabled: boolean,
          identification: nil | binary,
          name: nil | binary,
          email: nil | binary,
          contact_person: nil | binary,
          invoicing_address: nil | binary,
          shipping_address: nil | binary,
          net_amount: integer,
          gross_amount: integer,
          notes: nil | binary,
          terms: nil | binary,
          meta_attributes: nil | map,
          customer_id: nil | pos_integer(),
          series_id: nil | pos_integer(),
          currency: nil | <<_::24>>,
          days_to_due: nil | integer,
          items: nil | map,
          send_by_email: boolean,
          max_ocurrences: nil | pos_integer(),
          period: nil | pos_integer,
          period_type: nil | binary,
          starting_date: nil | Date.t(),
          finishing_date: nil | Date.t(),
          customer: Ecto.Association.NotLoaded.t() | Customer.t(),
          series: Ecto.Association.NotLoaded.t() | [Series.t()],
          invoices: Ecto.Association.NotLoaded.t() | [Invoice.t()],
          updated_at: nil | DateTime.t(),
          inserted_at: nil | DateTime.t()
        }

  schema "recurring_invoices" do
    field :identification, :string
    field :name, :string
    field :email, :string
    field :contact_person, :string
    field :invoicing_address, :string
    field :shipping_address, :string
    field :net_amount, :integer, default: 0
    field :gross_amount, :integer, default: 0
    field :send_by_email, :boolean, default: false
    field :days_to_due, :integer
    field :enabled, :boolean, default: true
    field :taxes_amounts, :map, virtual: true, default: %{}
    field :max_ocurrences, :integer
    field :period, :integer
    field :period_type, :string
    field :starting_date, :date
    field :finishing_date, :date
    field :currency, :string
    field :notes, :string
    field :terms, :string
    field :meta_attributes, :map, default: %{}
    belongs_to :customer, Customer, on_replace: :nilify
    belongs_to :series, Series
    has_many :invoices, Invoice, on_replace: :delete
    embeds_many :items, Item, on_replace: :delete, primary_key: false do
      field :quantity, :integer, default: 1
      field :discount, :integer, default: 0
      field :description, :string
      field :unitary_cost, :integer, default: 0
      field :base_amount, :integer, virtual: true, default: 0
      field :net_amount, :integer, virtual: true, default: 0
      field :taxes_amount, :map, virtual: true, default: %{}
      field :virtual_unitary_cost, :decimal, virtual: true
      field :taxes, {:array, :string}
    end

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(recurring_invoice, attrs) do
    recurring_invoice
    |> cast(attrs, @fields)
    |> assign_currency()
    #|> transform_items()
    #|> validate_items()
    #|> apply_changes_items()
    |> cast_embed(:items, with: &Item.changeset_for_recurring/2, sort_param: :items_sort, drop_param: :items_drop)
    |> Invoice.calculate()
    #|> unapply_changes_items()
    |> validate_required([:starting_date, :period, :period_type])
    |> foreign_key_constraint(:series_id)
    |> foreign_key_constraint(:customer_id)
    |> validate_inclusion(:period_type, ["Daily", "Monthly", "Yearly"])
    |> validate_number(:period, greater_than_or_equal_to: 0)
    |> validate_format(:email, @email_regex)
    |> validate_length(:name, max: 100)
    |> validate_length(:identification, max: 50)
    |> validate_length(:email, max: 100)
    |> validate_length(:contact_person, max: 100)
    |> validate_length(:currency, max: 3)
  end

end

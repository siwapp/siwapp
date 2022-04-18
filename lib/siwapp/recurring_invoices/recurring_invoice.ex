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
    :items,
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
    field :items, :map, default: %{}
    belongs_to :customer, Customer, on_replace: :nilify
    belongs_to :series, Series
    has_many :invoices, Invoice, on_replace: :delete

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t()
  @doc false
  def changeset(recurring_invoice, attrs) do
    recurring_invoice
    |> cast(attrs, @fields)
    |> assign_currency()
    |> transform_items()
    |> validate_items()
    |> apply_changes_items()
    |> calculate()
    |> unapply_changes_items()
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

  @doc """
  Converts field items from list of Item changesets to list of maps when
  changeset is valid to be able to save in database
  """
  @spec untransform_items(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def untransform_items(%{valid?: true} = changeset) do
    items = get_field(changeset, :items)

    items =
      items
      |> Enum.map(&make_item(&1.data))
      |> Enum.with_index()
      |> Map.new(fn {item, i} -> {i, item} end)

    put_change(changeset, :items, items)
  end

  def untransform_items(changeset), do: changeset

  @spec fields :: [atom]
  def fields, do: @fields

  # Converts field items from list of maps to list of Item changesets.
  # This is used to handle items validation and calculations
  @spec transform_items(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp transform_items(changeset) do
    currency = get_field(changeset, :currency)

    items_transformed =
      Enum.map(get_field(changeset, :items), fn {_i, item} ->
        Item.changeset(%Item{}, item, currency)
      end)

    put_change(changeset, :items, items_transformed)
  end

  # Adds error to changeset if any item is invalid
  @spec validate_items(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_items(changeset) do
    items_valid? =
      changeset
      |> get_field(:items)
      |> Enum.all?(& &1.valid?)

    if items_valid? do
      changeset
    else
      add_error(changeset, :items, "Items are invalid")
    end
  end

  # Applies changes (builds Item struct) to each Item changeset in field items.
  # Used to recycle calculate functions in invoice_helper, that use Item structs
  @spec apply_changes_items(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp apply_changes_items(changeset) do
    items =
      changeset
      |> get_field(:items)
      |> Enum.map(&apply_changes(&1))

    put_change(changeset, :items, items)
  end

  # Converts each Item struct in a changeset (changing empty map).
  # Used to recycle add_item, remove_item functions in views and
  # build item forms' for user to fill
  @spec unapply_changes_items(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp unapply_changes_items(changeset) do
    items = get_field(changeset, :items)
    currency = get_field(changeset, :currency)
    items_changeset = Enum.map(items, &Item.changeset(&1, %{}, currency))

    put_change(changeset, :items, items_changeset)
  end

  @spec make_item(Item.t()) :: map
  defp make_item(%Item{description: d, quantity: q, unitary_cost: u, discount: di, taxes: t}) do
    %{
      "description" => d,
      "quantity" => q,
      "unitary_cost" => u,
      "discount" => di,
      "taxes" => Enum.map(t, & &1.name)
    }
  end
end

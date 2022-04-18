defmodule Siwapp.Customers.Customer do
  @moduledoc """
  Customer
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Siwapp.Invoices.Invoice
  alias Siwapp.RecurringInvoices.RecurringInvoice

  @fields [
    :name,
    :identification,
    :hash_id,
    :email,
    :contact_person,
    :invoicing_address,
    :shipping_address,
    :meta_attributes
  ]

  @email_regex Application.compile_env!(:siwapp, :email_regex)

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          name: binary | nil,
          identification: binary | nil,
          hash_id: binary | nil,
          email: binary | nil,
          contact_person: binary | nil,
          invoicing_address: binary | nil,
          shipping_address: binary | nil,
          meta_attributes: map | nil,
          total: integer | nil,
          paid: integer | nil,
          currencies: [String.t()] | [] | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "customers" do
    field :identification, :string
    field :name, :string
    field :hash_id, :string
    field :email, :string
    field :contact_person, :string
    field :invoicing_address, :string
    field :shipping_address, :string
    field :meta_attributes, :map, default: %{}
    field :total, :integer, virtual: true
    field :paid, :integer, virtual: true
    field :currencies, {:array, :string}, virtual: true
    has_many :recurring_invoices, RecurringInvoice
    has_many :invoices, Invoice

    timestamps()
  end

  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(customer, attrs \\ %{}) do
    customer
    |> cast(attrs, @fields)
    |> validate_required_customer([:name, :identification])
    |> put_hash_id()
    |> unique_constraint(:identification)
    |> unique_constraint(:hash_id)
    |> validate_format(:email, @email_regex)
    |> validate_length(:name, max: 100)
    |> validate_length(:identification, max: 50)
    |> validate_length(:email, max: 100)
    |> validate_length(:contact_person, max: 100)
  end

  @spec create_hash_id(binary, binary) :: binary
  def create_hash_id(identification, name) do
    Base.encode16(:crypto.hash(:md5, "#{normalize(identification)}#{normalize(name)}"))
  end

  @doc """
  Returns module fields
  """
  @spec fields :: [atom]
  def fields, do: @fields

  @spec normalize(binary) :: binary
  defp normalize(string) do
    string
    |> String.downcase()
    |> String.replace(~r/ +/, "")
  end

  # Validates if either a name or an identification is set
  @spec validate_required_customer(Ecto.Changeset.t(), list) :: Ecto.Changeset.t()
  defp validate_required_customer(changeset, fields) do
    if Enum.any?(fields, &get_field(changeset, &1)) do
      changeset
    else
      add_error(changeset, hd(fields), "Either name or identification are required")
    end
  end

  @spec put_hash_id(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_hash_id(changeset) do
    name = get_field_or_empty(changeset, :name)
    identification = get_field_or_empty(changeset, :identification)

    put_change(changeset, :hash_id, create_hash_id(identification, name))
  end

  @spec get_field_or_empty(Ecto.Changeset.t(), atom) :: binary
  defp get_field_or_empty(changeset, field) do
    get_field(changeset, field) || ""
  end
end

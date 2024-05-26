defmodule Siwapp.Invoices.Item do
  @moduledoc """
  The Item schema has multiple virtual fields:

    - `virtual_unitary_cost` is just a human representation of the `unitary_cost`,
      because `unitary_cost` is always in cents like 12900, the `virtual_unitary_cost`
      would be 129.00

    - `base_amount` is the `quantity` * `unitary_cost`.

    - `net_amount` is the `base_amount` with the `discount` applied.

    - `taxes_amount` is a map containing something like:
          %{
            "VAT 0%" => Decimal.new("0.0"),
            "VAT 21%" => Decimal.new("2562.00")
          }
      It contains the amounts for each tax applied to the item.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Siwapp.Commons
  alias Siwapp.Commons.Tax
  alias Siwapp.Invoices.Invoice

  @fields [
    :quantity,
    :discount,
    :description,
    :unitary_cost,
    :virtual_unitary_cost
  ]

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          quantity: pos_integer(),
          discount: non_neg_integer(),
          description: binary() | nil,
          unitary_cost: integer(),
          invoice_id: pos_integer() | nil
        }

  schema "items" do
    field :quantity, :integer, default: 1
    field :discount, :integer, default: 0
    field :description, :string
    field :unitary_cost, :integer, default: 0
    field :base_amount, :integer, virtual: true, default: 0
    field :net_amount, :integer, virtual: true, default: 0
    field :taxes_amount, :map, virtual: true, default: %{}
    field :virtual_unitary_cost, :decimal, virtual: true
    belongs_to :invoice, Invoice

    many_to_many :taxes, Tax,
      join_through: "items_taxes",
      on_replace: :delete
  end

  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(item, attrs \\ %{}) do
    item
    |> cast(attrs, [:invoice_id | @fields])
    |> assoc_taxes(attrs)
    |> foreign_key_constraint(:invoice_id)
    |> common_validations()
  end

  @doc """
  Changeset for the recurring invoice items
  """
  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset_for_recurring(item, attrs \\ %{}) do
    item
    |> cast(attrs, [:taxes | @fields])
    |> common_validations()
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  defp common_validations(changeset) do
    changeset
    |> validate_length(:description, max: 20_000)
    |> validate_number(:quantity, greater_than_or_equal_to: 0)
    |> validate_number(:discount, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> set_amounts()
    |> set_taxes_amount()
  end

  @doc """
  Builds the map for the `taxes_amount` field.

  Since `taxes` are different data structures for Invoices and RecurringInvoices
  this function deals with both of them.
  """
  def get_taxes_amount(taxes, net_amount) do
    for tax <- taxes, into: %{} do
      if is_struct(tax, Siwapp.Commons.Tax) do
        tax_val = Decimal.new("#{tax.value / 100}")
        {tax.name, Decimal.mult(net_amount, tax_val)}
      else
        # here for RecurringInvoices tax is just something like "VAT 21%"
        tax_val =
          :cache
          |> Commons.list_taxes()
          |> Enum.find(&(&1.name == tax))
          |> Map.get(:value)
          |> Kernel./(100)
          |> Float.to_string()
          |> Decimal.new()

        {tax, Decimal.mult(net_amount, tax_val)}
      end
    end
  end

  @doc """
  Makes the calculations for `base_amount` and `net_amount`
  """
  @spec get_amounts(integer, integer, integer) :: {integer, integer}
  def get_amounts(quantity, unitary_cost, discount) do
    base_amount = quantity * unitary_cost
    net_amount = round(base_amount * (1 - discount / 100))
    {base_amount, net_amount}
  end

  @spec set_amounts(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp set_amounts(changeset) do
    quantity = get_field(changeset, :quantity)
    unitary_cost = get_field(changeset, :unitary_cost)
    discount = get_field(changeset, :discount)
    {base_amount, net_amount} = get_amounts(quantity, unitary_cost, discount)

    changeset
    |> put_change(:base_amount, base_amount)
    |> put_change(:net_amount, net_amount)
  end

  @spec set_taxes_amount(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp set_taxes_amount(changeset) do
    case get_field(changeset, :taxes) do
      [] ->
        changeset

      taxes ->
        net_amount = get_field(changeset, :net_amount)
        taxes_amount = get_taxes_amount(taxes, net_amount)

        put_change(changeset, :taxes_amount, taxes_amount)
    end
  end

  @spec assoc_taxes(Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  defp assoc_taxes(changeset, attrs) do
    changeset_taxes_names =
      Enum.map(get_field(changeset, :taxes), &String.upcase(&1.name))

    attr_taxes_names = MapSet.new(get(attrs, :taxes) || changeset_taxes_names, &String.upcase/1)
    all_taxes = Commons.list_taxes(:cache)
    all_taxes_names = MapSet.new(all_taxes, & &1.name)

    changeset =
      Enum.reduce(attr_taxes_names, changeset, &check_wrong_taxes(&1, &2, all_taxes_names))

    put_assoc(changeset, :taxes, Enum.filter(all_taxes, &(&1.name in attr_taxes_names)))
  end

  @spec check_wrong_taxes(String.t(), Ecto.Changeset.t(), MapSet.t()) :: Ecto.Changeset.t()
  defp check_wrong_taxes(tax_name, changeset, all_taxes_names) do
    if MapSet.member?(all_taxes_names, tax_name) do
      changeset
    else
      add_error(changeset, :taxes, "The tax #{tax_name} is not defined")
    end
  end

  @spec get(map(), atom()) :: any()
  defp get(map, key) when is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end

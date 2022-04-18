defmodule Siwapp.Customers do
  @moduledoc """
  The Customers context.
  """
  import Ecto.Query, warn: false

  alias Siwapp.Customers.Customer
  alias Siwapp.Customers.CustomerQuery
  alias Siwapp.Query
  alias Siwapp.Repo

  @doc """
  Lists customers in database
  """
  @spec list(non_neg_integer(), non_neg_integer()) :: [Customer.t()]
  def list(limit \\ 100, offset \\ 0), do: Repo.all(CustomerQuery.list(limit, offset))

  @doc """
  Lists customers in database following CustomerQuery.list_with_assoc_invoice_fields/2 query
  """
  @spec list_with_assoc_invoice_fields(Ecto.Queryable.t(), non_neg_integer(), non_neg_integer()) ::
          [Customer.t()]
  def list_with_assoc_invoice_fields(query, limit \\ 100, offset \\ 0),
    do: Repo.all(CustomerQuery.list_with_assoc_invoice_fields(query, limit, offset))

  @spec suggest_by_name(binary | nil, keyword()) :: list
  def suggest_by_name(name, options \\ [])
  def suggest_by_name("", _options), do: []
  def suggest_by_name(nil, _options), do: []

  def suggest_by_name(name, options) do
    default = [limit: 100, offset: 0]
    options = Keyword.merge(default, options)

    Customer
    |> Query.search_in_string(:name, "%#{name}%")
    |> limit(^options[:limit])
    |> offset(^options[:offset])
    |> select([c], {c.name, c.id})
    |> Repo.all()
  end

  @doc """
  Create a new customer
  """
  @spec create(map) :: {:ok, Customer.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs \\ %{}) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update a customer
  """
  @spec update(Customer.t(), map) :: Customer.t()
  def update(%Customer{} = customer, attrs) do
    customer
    |> Customer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete a customer
  """
  @spec delete(Customer.t()) :: {:ok, Customer.t()} | {:error, binary}
  def delete(%Customer{} = customer) do
    Repo.delete(customer)
  rescue
    _e in Ecto.ConstraintError ->
      {:error, "It's forbidden to delete a customer with associated invoices/recurring invoices"}
  end

  @doc """
  Gets a customer by id
  """
  @spec get!(binary | integer) :: Customer.t()
  def get!(id), do: Repo.get!(Customer, id)
  @spec get!(binary, atom) :: Customer.t()
  def get!(id, :preload), do: Customer |> Repo.get!(id) |> Repo.preload([:invoices])

  @doc """
  Gets a customer by id
  """
  @spec get(binary) :: Customer.t() | nil
  def get(id), do: Repo.get(Customer, id)

  @spec get(binary | nil, binary | nil) :: Customer.t() | nil
  def get(nil, nil), do: nil
  def get(nil, name), do: get_by_hash_id("", name)
  def get(identification, nil), do: get(identification, "")

  def get(identification, name) do
    case Repo.get_by(Customer, identification: identification) do
      nil -> get_by_hash_id(identification, name)
      customer -> customer
    end
  end

  @spec change(Customer.t(), map) :: Ecto.Changeset.t()
  def change(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end

  @spec get_by_hash_id(binary, binary) :: Customer.t() | nil
  defp get_by_hash_id(identification, name) do
    hash_id = Customer.create_hash_id(identification, name)

    case Repo.get_by(Customer, hash_id: hash_id) do
      nil -> nil
      customer -> customer
    end
  end
end

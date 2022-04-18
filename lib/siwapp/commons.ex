defmodule Siwapp.Commons do
  @moduledoc """
  The Commons context. It handles Series and Taxes.
  """

  import Ecto.Query, warn: false

  alias Siwapp.Commons.Series
  alias Siwapp.Commons.Tax
  alias Siwapp.Repo

  ### SERIES ###

  @doc """
  Returns the list of series.

  ## Examples

      iex> list_series()
      [%Series{}, ...]

  """
  @spec list_series :: [Series.t()]
  def list_series do
    Series
    |> order_by(asc: :id)
    |> Repo.all()
  end

  @doc """
  Gets a single series.

  ## Examples

      iex> get_series(2)
      %Series{}

      iex> get_series(5)
      nil
        # because that series doesn't exist

  """
  @spec get_series(non_neg_integer) :: Series.t() | nil
  def get_series(id), do: Repo.get(Series, id)

  @doc """
  Creates a series.

  ## Examples

      iex> create_series(%{name: "A-Series", value: "hsu384h"})
      {:ok, %Series{}}

      iex> create_series(%{name: "A-Series"})
      {:error, %Ecto.Changeset{}}
        # because value field is required

      iex> create_series(%{default: true})
      {:error, "You cannot directly assign..."}

  """
  @spec create_series(map) :: {:ok, Series.t()} | {:error, any()}
  def create_series(attrs \\ %{})

  def create_series(%{default: _}) do
    {:error,
     "You cannot directly assign the default key. Use the change_default_series/1 function instead."}
  end

  def create_series(attrs) do
    result = insert_new_series(attrs)

    with {:ok, series} <- result do
      if length(list_series()) == 1, do: change_default_series(series)
    end

    result
  end

  @doc """
  Updates a series.

  ## Examples

      iex> update_series(series, %{name: "hsu384h"})
      {:ok, %Series{}}

      iex> update_series(series, %{name: *very_very_long_new_name*})
      {:error, %Ecto.Changeset{}}

      iex> update_series(%{default: true})
      {:error, "You cannot directly assign..."}

  """
  @spec update_series(Series.t(), map) :: {:ok, Series.t()} | {:error, any()}
  def update_series(_series, %{default: _}) do
    {:error,
     "You cannot directly assign the default key. Use the change_default_series/1 function instead."}
  end

  def update_series(%Series{} = series, attrs) do
    series
    |> Series.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets the unique series that has the default attribute set to 'true'
  ## Examples
      iex> get_default_series
      %Series{}
      iex> get_default_series
      nil
        # there is no default series
  """
  @spec get_default_series :: Series.t() | nil
  def get_default_series do
    Repo.get_by(Series, default: true)
  end

  @doc """
  Choose a new series for being the default one. You can call this function without
  parameters, so the default series will be the first one in the list of Series; or with
  a 'series' given, so that series will be the default.

  ## Examples

      iex> change_default_series(series)
      {:ok, %Series{}}
        # That series now has the default attribute as true, and the others as false

      iex> change_default_series(series)
      {:error, %Ecto.Changeset{}}
        # That series doesn't exist
  """
  @spec change_default_series(Series.t()) :: {:ok, Series.t()} | {:error, Ecto.Changeset.t()}
  def change_default_series(default_series) do
    for series <- list_series() do
      update_default_series(series, false)
    end

    update_default_series(default_series, true)
  end

  @doc """
  Deletes a series.

  ## Examples

      iex> delete_series(series)
      {:ok, %Series{}}

      iex> delete_series(series)
      {:error, %Ecto.Changeset{}}
        # because that series doesn't exist

      iex> delete_series(series)
      {:error, "The series you're aiming..."}
        # because that series is the default one

  """
  @spec delete_series(Series.t()) :: {:ok, Series.t()} | {:error, binary}
  def delete_series(%Series{} = series) do
    if series.default do
      {:error, "The series you're aiming to delete is the default series. \
      Change the default series first"}
    else
      Repo.delete(series)
    end
  rescue
    _e in Ecto.ConstraintError ->
      {:error, "It's forbidden to delete a series with associated invoices"}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking series changes.

  ## Examples

      iex> change_series(series)
      %Ecto.Changeset{data: %Series{}}

  """
  @spec change_series(Series.t(), map) :: Ecto.Changeset.t()
  def change_series(%Series{} = series, attrs \\ %{}) do
    Series.changeset(series, attrs)
  end

  @spec list_series_names :: [binary()]
  def list_series_names do
    Series
    |> select([s], s.name)
    |> Repo.all()
  end

  @spec series_id_by_code(binary()) :: integer | nil
  def series_id_by_code(code) do
    Series
    |> where([s], s.code == ^code)
    |> select([s], s.id)
    |> Repo.one()
  end

  @spec insert_new_series(map()) :: {:ok, Series.t()} | {:error, Ecto.Changeset.t()}
  defp insert_new_series(attrs) do
    %Series{}
    |> Series.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_default_series(Series.t(), boolean()) ::
          {:ok, Series.t()} | {:error, Ecto.Changeset.t()}
  defp update_default_series(series, value) do
    series
    |> Series.changeset(%{default: value})
    |> Repo.update()
  end

  ### TAXES ###

  @doc """
  Returns the list of taxes.

  ## Examples

      iex> list_taxes()
      [%Tax{}, ...]

  """
  @spec list_taxes :: [Tax.t()]
  def list_taxes do
    Tax
    |> order_by(asc: :id)
    |> Repo.all()
  end

  @spec list_taxes(:cache) :: [Tax.t()]
  def list_taxes(:cache) do
    case Cachex.get(:siwapp_cache, :taxes) do
      {:ok, nil} ->
        taxes = list_taxes()
        Cachex.put(:siwapp_cache, :taxes, taxes, ttl: :timer.minutes(5))
        taxes

      {:ok, taxes} ->
        taxes
    end
  end

  @spec default_taxes_names :: [binary]
  def default_taxes_names do
    :cache
    |> list_taxes()
    |> Enum.filter(& &1.default)
    |> Enum.map(& &1.name)
  end

  @doc """
  Returns a Keyword List, with the list of taxes, being the key
  a String with the name of the tax and the value its id, appropiate
  for multiselect inputs.

  ## Examples

      iex> list_taxes_for_multiselect()
      ["VAT": 1, "RETENTION": 2]

  """
  @spec list_taxes_for_multiselect :: [String.t()]
  def list_taxes_for_multiselect do
    Tax
    |> Repo.all()
    |> Enum.map(&{&1.name, &1.id})
  end

  @doc """
  Gets a single tax.

  Raises `Ecto.NoResultsError` if the Tax does not exist.

  ## Examples

      iex> get_tax!(2)
      %Tax{}

      iex> get_tax!(5)
      ** (Ecto.NoResultsError)

  """
  @spec get_tax!(non_neg_integer) :: Tax.t()
  def get_tax!(id), do: Repo.get!(Tax, id)

  @doc """
  Creates a tax.

  ## Examples

      iex> create_tax(%{name: "VAT", value: 21.0})
      {:ok, %Tax{}}

      iex> create_tax(%{})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_tax(map) :: {:ok, Tax.t()} | {:error, Ecto.Changeset.t()}
  def create_tax(attrs \\ %{}) do
    %Tax{}
    |> Tax.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tax.

  ## Examples

      iex> update_tax(tax, %{value: 18.0})
      {:ok, %Tax{}}

      iex> update_tax(tax, %{value: "not a number"})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_tax(Tax.t(), map) ::
          {:ok, Tax.t()} | {:error, Ecto.Changeset.t()}
  def update_tax(%Tax{} = tax, attrs) do
    tax
    |> Tax.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Change the default tax, setting the attribute 'default' of the taxes
  with the given 'tax_id' to true or false.

  ## Examples

      iex> set_default_tax(3)
      {:ok, %Series{}}

  """
  @spec set_default_tax(non_neg_integer) :: {:ok, Tax.t()}
  def set_default_tax(id) do
    tax = get_tax!(id)

    tax
    |> Tax.changeset(%{"default" => not tax.default})
    |> Repo.update()
  end

  @doc """
  Deletes a tax.

  ## Examples

      iex> delete_tax(tax)
      {:ok, %Tax{}}

      iex> delete_tax(tax)
      {:error, %Ecto.Changeset{}}
        # because that tax doesn't exist

  """
  @spec delete_tax(Tax.t()) :: {:ok, Tax.t()} | {:error, Ecto.Changeset.t()}
  def delete_tax(%Tax{} = tax) do
    if Siwapp.RecurringInvoices.tax_in_any_recurring_invoice?(tax.name) do
      {:error, "It's forbidden to delete a tax with associated invoices/recurring invoices"}
    else
      Repo.delete(tax)
    end
  rescue
    _e in Ecto.ConstraintError ->
      {:error, "It's forbidden to delete a tax with associated invoices/recurring invoices"}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tax changes.

  ## Examples

      iex> change_tax(tax)
      %Ecto.Changeset{data: %Tax{}}

  """
  @spec change_tax(Tax.t(), map) :: Ecto.Changeset.t()
  def change_tax(%Tax{} = tax, attrs \\ %{}) do
    Tax.changeset(tax, attrs)
  end
end

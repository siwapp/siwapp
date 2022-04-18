defmodule Siwapp.CommonsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Siwapp.Commons` context.
  """

  alias Siwapp.Commons

  @spec unique_series_name :: binary
  def unique_series_name, do: "#{System.unique_integer()}"

  @spec unique_series_code :: binary
  def unique_series_code, do: "#{System.unique_integer()}"

  @spec unique_taxes_name :: binary
  def unique_taxes_name, do: "#{System.unique_integer()}"

  @spec unique_taxes_value :: integer
  def unique_taxes_value, do: :rand.uniform(30)

  @spec series_fixture(map()) :: Commons.Series.t()
  def series_fixture(attrs \\ %{}) do
    {:ok, series} =
      attrs
      |> valid_series_attributes()
      |> Commons.create_series()

    series
  end

  @spec valid_series_attributes(map()) :: map()
  def valid_series_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_series_name(),
      code: unique_series_code(),
      first_number: 1
    })
  end

  @spec taxes_fixture(map()) :: Commons.Tax.t()
  def taxes_fixture(attrs \\ %{}) do
    {:ok, tax} =
      attrs
      |> valid_taxes_attributes()
      |> Commons.create_tax()

    tax
  end

  @spec valid_taxes_attributes(map()) :: map()
  def valid_taxes_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_taxes_name(),
      value: unique_taxes_value()
    })
  end
end

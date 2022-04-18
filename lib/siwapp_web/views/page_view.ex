defmodule SiwappWeb.PageView do
  use SiwappWeb, :view

  @doc """
  Returns a string of money, which is formed by amount and currency. Options
  can be given. Default are [symbol: true, separator: ","]. Check Money.to_string
  to see more options available
  """
  @spec money_format(number, atom | binary, keyword) :: binary
  def money_format(value, currency, options \\ []) do
    value
    |> Money.new(currency)
    |> Money.to_string(options)
  end

  @spec reference(binary, integer) :: binary
  def reference(series_code, number), do: series_code <> "-#{number}"
end

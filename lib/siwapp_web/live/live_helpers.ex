defmodule SiwappWeb.LiveHelpers do
  @moduledoc false
  import Phoenix.LiveView.Helpers

  @spec type_of_period(binary, integer) :: binary
  def type_of_period(period_type, period) do
    case period_type do
      "Daily" -> singular_or_plural(period, "day")
      "Monthly" -> singular_or_plural(period, "month")
      "Yearly" -> singular_or_plural(period, "year")
    end
  end

  @spec singular_or_plural(integer, binary) :: binary
  defp singular_or_plural(period, str) do
    if period > 1 do
      str <> "s"
    else
      str
    end
  end

  @spec maybe_add(list, list) :: {list, non_neg_integer()}
  def maybe_add(current_list, []) do
    {current_list, 1}
  end

  def maybe_add(current_list, next_list) do
    {current_list ++ next_list, 0}
  end
end

defmodule SiwappWeb.LiveHelpers do
  @moduledoc false

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

  @spec remove_unused_meta_attributes(map()) :: map()
  def remove_unused_meta_attributes(%{"meta_attributes" => attributes} = params)
      when is_map(attributes) do
    Map.put(params, "meta_attributes", remove_unused_fields(attributes))
  end

  def remove_unused_meta_attributes(params), do: params

  @spec remove_unused_fields(map()) :: map()
  def remove_unused_fields(params) do
    Map.reject(params, fn
      {key, _value} when is_binary(key) -> String.starts_with?(key, "_unused_")
      {_key, _value} -> false
    end)
  end
end

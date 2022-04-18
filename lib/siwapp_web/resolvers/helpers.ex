defmodule SiwappWeb.Resolvers.Helpers do
  @moduledoc false

  @spec maybe_change_meta_attributes(map) :: map
  def maybe_change_meta_attributes(%{meta_attributes: meta_params} = params) do
    meta_params =
      Enum.reduce(meta_params, %{}, fn map, acc ->
        value = if(Map.has_key?(map, :value), do: map.value, else: nil)

        Map.put(acc, map.key, value)
      end)

    Map.put(params, :meta_attributes, meta_params)
  end

  def maybe_change_meta_attributes(params) do
    params
  end
end

defmodule SiwappWeb.Schema.MetaAttributeTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :meta_attribute do
    field :key, :string do
      resolve(fn meta_attributes, _, _ ->
        {key, _} = meta_attributes

        {:ok, key}
      end)
    end

    field :value, :string do
      resolve(fn meta_attributes, _, _ ->
        {_, val} = meta_attributes

        {:ok, val}
      end)
    end
  end
end

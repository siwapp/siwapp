defmodule Siwapp.Query do
  @moduledoc """
  Generic Querys
  """
  import Ecto.Query

  @spec by(Ecto.Queryable.t(), atom, any) :: Ecto.Query.t()
  def by(query, field, value), do: where(query, ^[{field, value}])

  @spec list_preload(Ecto.Queryable.t(), atom | [atom]) :: Ecto.Query.t()
  def list_preload(query, term) do
    preload(query, ^term)
  end

  @doc """
  Returns a value for the specific field from db which matches with the string_search_value
  """
  @spec search_in_string(Ecto.Queryable.t(), atom, binary) :: Ecto.Query.t()
  def search_in_string(query, field, string_search_value) do
    where(query, [q], ilike(field(q, ^field), ^string_search_value))
  end

  @spec not_deleted(Ecto.Queryable.t()) :: Ecto.Query.t()
  def not_deleted(query) do
    where(query, [q], is_nil(q.deleted_at))
  end
end

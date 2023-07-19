defmodule Siwapp.Searches.Search.CSVMetaAttributes do
  @moduledoc """
  CSV Meta Attributes
  """

  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :key, :string
  end

  @spec changeset(map, map) :: Ecto.Changeset.t()
  def changeset(csv_meta_attributes, params) do
    cast(csv_meta_attributes, params, [:key])
  end
end

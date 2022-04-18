defmodule Siwapp.Searches.Search do
  @moduledoc """
  Search
  """
  import Ecto.Changeset

  @types %{
    search_input: :string,
    name: :string,
    issue_from_date: :date,
    issue_to_date: :date,
    starting_from_date: :date,
    starting_to_date: :date,
    finishing_from_date: :date,
    finishing_to_date: :date,
    series: :string,
    status: :string,
    key: :string,
    value: :string,
    number: :integer
  }

  @type t :: %__MODULE__{
          search_input: binary | nil,
          name: binary | nil,
          issue_from_date: Date.t() | nil,
          issue_to_date: Date.t() | nil,
          starting_from_date: Date.t() | nil,
          starting_to_date: Date.t() | nil,
          finishing_from_date: Date.t() | nil,
          finishing_to_date: Date.t() | nil,
          series: binary | nil,
          status: binary | nil,
          key: binary | nil,
          value: binary | nil,
          number: integer | nil
        }

  defstruct [
    :search_input,
    :name,
    :issue_from_date,
    :issue_to_date,
    :starting_from_date,
    :starting_to_date,
    :finishing_from_date,
    :finishing_to_date,
    :series,
    :status,
    :key,
    :value,
    :number
  ]

  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(search, attrs \\ %{}) do
    cast({search, @types}, attrs, Map.keys(@types))
  end
end

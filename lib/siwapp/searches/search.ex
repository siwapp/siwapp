defmodule Siwapp.Searches.Search do
  @moduledoc """
  Search
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Siwapp.Searches.Search.CSVMetaAttributes

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
          number: integer | nil,
          csv_meta_attributes: list()
        }

  embedded_schema do
    field :search_input, :string
    field :name, :string
    field :issue_from_date, :date
    field :issue_to_date, :date
    field :starting_from_date, :date
    field :starting_to_date, :date
    field :finishing_from_date, :date
    field :finishing_to_date, :date
    field :series, :string
    field :status, :string
    field :key, :string
    field :value, :string
    field :number, :integer

    embeds_many :csv_meta_attributes, CSVMetaAttributes
  end

  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(search, attrs \\ %{}) do
    fields = __schema__(:fields) -- __schema__(:embeds)

    search
    |> cast(attrs, fields)
    |> cast_embed(:csv_meta_attributes,
      with: &CSVMetaAttributes.changeset/2
    )
  end
end

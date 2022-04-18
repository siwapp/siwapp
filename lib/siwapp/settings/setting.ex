defmodule Siwapp.Settings.Setting do
  @moduledoc """
  A Setting's a schema used to manage settings database, which has key and value columns. Therefore,
  no matter which key, values are always strings.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: nil | integer,
          key: nil | binary,
          value: nil | binary,
          inserted_at: nil | DateTime.t(),
          updated_at: nil | DateTime.t()
        }

  schema "settings" do
    field :key, :string
    field :value, :string

    timestamps()
  end

  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(setting, attrs \\ %{}) do
    setting
    |> cast(attrs, [:key, :value])
    |> validate_required([:key])
    |> unique_constraint(:key)
  end
end

defmodule Siwapp.Templates.Template do
  @moduledoc """
  Template
  """
  use Ecto.Schema

  import Ecto.Changeset

  @fields [:name, :template, :print_default, :email_default, :subject]
  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          name: binary | nil,
          template: binary | nil,
          print_default: boolean(),
          email_default: boolean(),
          subject: binary | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "templates" do
    field :name, :string
    field :template, :string
    field :print_default, :boolean, default: false
    field :email_default, :boolean, default: false
    field :subject, :string

    timestamps()
  end

  @spec changeset(t(), map) :: Ecto.Changeset.t()
  def changeset(template, attrs \\ %{}) do
    template
    |> cast(attrs, @fields)
    |> validate_required([:name, :template])
    |> validate_length(:name, max: 255)
    |> validate_length(:subject, max: 200)
  end
end

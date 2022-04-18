defmodule Siwapp.Settings.SettingBundle do
  @moduledoc """
  SettingBundle is the data structure to manage SettingsController form operations. It's a struct, whose keys consist of
  all current settings available to change via form or terminal, updating settings values' of those already stored in db
  (which are initialized in the seeds)
  """
  import Ecto.Changeset

  @fields_keywordlist [
    company: :string,
    company_vat_id: :string,
    company_phone: :string,
    company_email: :string,
    company_website: :string,
    currency: :string,
    days_to_due: :integer,
    company_address: :string,
    legal_terms: :string
  ]

  @labels Keyword.keys(@fields_keywordlist)

  @email_regex Application.compile_env!(:siwapp, :email_regex)

  @type t :: %__MODULE__{
          company: binary | nil,
          company_vat_id: binary | nil,
          company_phone: binary | nil,
          company_email: binary | nil,
          company_website: binary | nil,
          currency: binary | nil,
          days_to_due: binary | nil,
          company_address: binary | nil,
          legal_terms: binary | nil
        }

  defstruct @labels

  @spec changeset(%__MODULE__{}, map) :: Ecto.Changeset.t()
  def changeset(setting_bundle, attrs \\ %{}) do
    {setting_bundle, fields_map()}
    |> cast(attrs, @labels)
    |> validate_email()
    # Example list of currency, will be updated to whole
    |> validate_length(:currency, max: 3)
    |> validate_days_to_due()
  end

  @spec fields_map :: map
  defp fields_map, do: Map.new(@fields_keywordlist)

  @spec validate_email(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_email(changeset) do
    changeset
    |> validate_format(:company_email, @email_regex, message: "must have the @ sign and no spaces")
    |> validate_length(:company_email, max: 160)
  end

  @spec validate_days_to_due(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_days_to_due(changeset) do
    days_to_due = get_field(changeset, :days_to_due)

    if days_to_due >= 0 do
      changeset
    else
      add_error(changeset, :days_to_due, "days to due cannot be negative")
    end
  end
end

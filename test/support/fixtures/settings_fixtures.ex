defmodule Siwapp.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Siwapp.Setings` context.
  """

  alias Siwapp.Settings

  @spec valid_settings_attributes(map) :: keyword()
  def valid_settings_attributes(attrs \\ []) do
    Keyword.merge(attrs,
      company: "Doofinder",
      company_vat_id: "1fg5t7",
      company_phone: "632778941",
      company_email: "demo@example.com",
      company_website: "www.mywebsite.com",
      currency: "USD",
      days_to_due: "0",
      company_address: "Newton Avenue, 32. NY",
      legal_terms: "Clauses of our contract"
    )
  end

  @spec settings_fixture(map) :: Siwapp.Settings.SettingBundle.t()
  def settings_fixture(attrs \\ []) do
    attrs
    |> valid_settings_attributes()
    |> Enum.each(&Settings.create/1)

    Settings.current_bundle()
  end
end

# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Siwapp.Repo.insert!(%Siwapp.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query, only: [from: 2]

# Start the Ecto repository
Enum.each([:postgrex, :ecto], &Application.ensure_all_started(&1))
Siwapp.Repo.start_link()

alias Siwapp.{
  Repo,
  Settings,
  Templates
}

alias Siwapp.Templates.Template

# SEEDING SETTINGS
settings = [
  currency: "USD",
  days_to_due: "#{Faker.random_between(0, 5)}"
]

Enum.each(settings, fn {key, _value} = setting ->
  if is_nil(Settings.get(key)), do: Settings.create(setting)
end)

# SEEDING TEMPLATES

{:ok, print_default} = File.read("#{__DIR__}/fixtures/print_default.html.heex")
{:ok, email_default} = File.read("#{__DIR__}/fixtures/email_default.html.heex")

unless Repo.exists?(from Template, where: [name: "Print Default"]) do
  Templates.create(%{
    name: "Print Default",
    template: print_default
  })
end

unless Repo.exists?(from Template, where: [name: "Email Default"]) do
  {:ok, email_template} =
    Templates.create(%{
      name: "Email Default",
      template: email_default,
      subject: "Invoice: <%= SiwappWeb.PageView.reference(series.code, number)%> "
    })

  Templates.set_default(:email, email_template)
end

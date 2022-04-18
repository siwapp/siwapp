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

alias Siwapp.{
  Settings,
  Templates
}

# SEEDING SETTINGS
settings = [
  currency: "USD",
  days_to_due: "#{Faker.random_between(0, 5)}"
]

Enum.each(settings, &Settings.create(&1))

# SEEDING TEMPLATES

{:ok, print_default} = File.read("#{__DIR__}/fixtures/print_default.html.heex")
{:ok, email_default} = File.read("#{__DIR__}/fixtures/email_default.html.heex")

Templates.create(%{
  name: "Print Default",
  template: print_default
})

{:ok, email_template} =
  Templates.create(%{
    name: "Email Default",
    template: email_default,
    subject: "Invoice: <%= SiwappWeb.PageView.reference(series.code, number)%> "
  })

Templates.set_default(:email, email_template)

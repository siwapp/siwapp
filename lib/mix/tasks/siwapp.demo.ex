defmodule Mix.Tasks.Siwapp.Demo do
  @shortdoc "Deletes all data and puts some demo data"

  @moduledoc """
  Only 'force' option can be provided in order to avoid
  being asked for confirmation. If any other is given,
  task won't be completed
  ## Examples

    $ mix siwapp.demo
    This will remove all data in database. Are you sure? [y/n]

    $ mix siwapp.demo force
    ...
    All data's been substituted by demo

    $ mix siwapp.demo DoesNotExistArg
    Sorry, can't understand that command
  """
  use Mix.Task

  alias Siwapp.Accounts
  alias Siwapp.Commons
  alias Siwapp.Customers
  alias Siwapp.Invoices
  alias Siwapp.RecurringInvoices
  alias Siwapp.Repo
  alias Siwapp.Settings
  alias Siwapp.Templates

  @models [
    Invoices.Item,
    Invoices.Payment,
    Accounts.User,
    Accounts.UserToken,
    Invoices.Invoice,
    RecurringInvoices.RecurringInvoice,
    Commons.Tax,
    Commons.Series,
    Customers.Customer,
    Settings.Setting,
    Templates.Template
  ]

  @impl Mix.Task
  def run(args) do
    Enum.each([:postgrex, :ecto, :cachex], &Application.ensure_all_started(&1))
    Siwapp.Repo.start_link()
    Cachex.start_link(:siwapp_cache)

    validate_args!(args)

    take_action(args)
  end

  @spec take_action(list) :: :ok | no_return()
  defp take_action(["force"]) do
    demo_db()
  end

  defp take_action(_args) do
    case IO.gets("\n This will remove all data in database. Are you sure? [y/n]\t") do
      "y\n" ->
        demo_db()

      _ ->
        IO.puts("Operation aborted")
    end
  end

  @spec validate_args!(list | term()) :: no_return()
  defp validate_args!(["force"]), do: :ok

  defp validate_args!([]), do: :ok

  defp validate_args!(_) do
    raise_with_help("Sorry, can't understand that command")
  end

  @spec raise_with_help(binary) :: no_return()
  defp raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix siwapp.demo only accepts 'force' argument as an
    option to confirm operation and avoid confirmation need

    You can try interactive task:
      mix siwapp.demo
    or force that with:
      mix siwapp.demo force
    """)
  end

  @spec demo_db :: :ok
  defp demo_db do
    sequence_name = fn x ->
      case x |> to_string() |> String.split(".") |> List.last() |> String.downcase() do
        "recurringinvoice" -> "recurring_invoice"
        "tax" -> "taxe"
        "series" -> "serie"
        model -> model
      end <> "s_id_seq"
    end

    Enum.each(
      @models,
      &(Repo.delete_all(&1) &&
          Repo.query("ALTER SEQUENCE #{sequence_name.(&1)} RESTART"))
    )

    settings = [
      company: "Doofinder",
      company_vat_id: "1fg5t7",
      company_phone: "632278941",
      company_email: "demo@example",
      company_website: "www.mywebsite.com",
      currency: "USD",
      days_to_due: "#{Faker.random_between(0, 5)}",
      company_address: "Newton Avenue, 32. NY",
      legal_terms: "Clauses of our contract"
    ]

    Enum.each(settings, &Settings.create(&1))

    {:ok, print_default} = File.read("priv/repo/fixtures/print_default.html.heex")
    {:ok, email_default} = File.read("priv/repo/fixtures/email_default.html.heex")

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

    series = [
      %{name: "A-series", code: "A"},
      %{name: "B-series", code: "B"},
      %{name: "C-series", code: "C"}
    ]

    Enum.each(series, &Commons.create_series(&1))

    taxes = [
      %{name: "VAT", value: 21, default: true},
      %{name: "RETENTION", value: -15}
    ]

    Enum.each(taxes, &Commons.create_tax(&1))

    customers = Enum.map(0..15, fn _i -> %{name: Faker.Person.name(), id: Faker.Code.issn()} end)

    Enum.each(
      customers,
      &Customers.create(%{
        name: &1.name,
        identification: &1.id,
        email: Faker.Internet.email(),
        contact_person: Faker.Person.name(),
        invoicing_address:
          "#{Faker.Address.street_address()}\n#{Faker.Address.postcode()} #{Faker.Address.country()}"
      })
    )

    currencies = ["USD", "USD", "USD", "EUR", "GBP"]
    booleans = [true, false]

    invoices =
      Enum.map(0..30, fn _i ->
        %{customer: Enum.random(customers), issue_date: Faker.Date.backward(31)}
      end)

    Enum.each(
      invoices,
      &Invoices.create(%{
        name: &1.customer.name,
        identification: &1.customer.id,
        paid: Enum.random(booleans),
        sent_by_email: Enum.random(booleans),
        issue_date: &1.issue_date,
        due_date: Date.add(&1.issue_date, Faker.random_between(1, 31)),
        series_id: Enum.random(Enum.map(Commons.list_series(), fn x -> x.id end)),
        currency: Enum.random(currencies),
        items: [
          %{
            quantity: Faker.random_between(1, 2),
            description: "#{Faker.App.name()} App Development",
            unitary_cost: Faker.random_between(10_000, 1_000_000),
            taxes: ["VAT", "RETENTION"]
          }
        ]
      })
    )

    period_types = ["Daily", "Monthly", "Yearly"]
    taxes_list = [["VAT"], ["RETENTION"], ["VAT", "RETENTION"], []]

    recurring_invoices =
      Enum.map(0..30, fn _i ->
        %{customer: Enum.random(customers), starting_date: Faker.Date.backward(31)}
      end)

    Enum.each(
      recurring_invoices,
      &RecurringInvoices.create(%{
        name: &1.customer.name,
        identification: &1.customer.id,
        period: Faker.random_between(1, 12),
        period_type: Enum.random(period_types),
        starting_date: &1.starting_date,
        series_id: Enum.random(Enum.map(Commons.list_series(), fn x -> x.id end)),
        currency: Enum.random(currencies),
        send_by_email: Enum.random(booleans),
        items: %{
          "0" => %{
            "quantity" => Faker.random_between(1, 2),
            "description" => "#{Faker.App.name()} App Development",
            "unitary_cost" => Faker.random_between(10_000, 1_000_000),
            "discount" => Faker.random_between(0, 5),
            "taxes" => Enum.random(taxes_list)
          }
        }
      })
    )

    Siwapp.Accounts.register_user(%{
      email: "demo@example.com",
      password: "secretsecret",
      admin: "true"
    })

    IO.puts("All data's been substituted by demo")
  end
end

defmodule Siwapp.Repo.Migrations.CreateRecurringInvoices do
  use Ecto.Migration

  def change do
    create table(:recurring_invoices) do
      add :name, :string, size: 100
      add :identification, :string, size: 50
      add :email, :string, size: 100
      add :contact_person, :string, size: 100
      add :invoicing_address, :text
      add :shipping_address, :text
      add :net_amount, :integer, default: 0
      add :gross_amount, :integer, default: 0
      add :send_by_email, :boolean, default: false
      add :days_to_due, :integer
      add :enabled, :boolean, default: true
      add :max_ocurrences, :integer
      add :period, :integer
      add :period_type, :string, size: 8
      add :starting_date, :date
      add :finishing_date, :date
      add :currency, :string, size: 3
      add :notes, :text
      add :terms, :text
      add :meta_attributes, :jsonb
      add :items, :jsonb
      add :series_id, references(:series, type: :integer)
      add :customer_id, references(:customers, type: :integer), null: false

      timestamps()
    end

    create index(:recurring_invoices, [:contact_person])
    create index(:recurring_invoices, [:identification])
    create index(:recurring_invoices, [:email])
    create index(:recurring_invoices, [:name])
    create index(:recurring_invoices, [:customer_id])
    create index(:recurring_invoices, [:series_id])

    alter table(:invoices) do
      add :recurring_invoice_id,
          references(:recurring_invoices, type: :integer, on_delete: :nilify_all)
    end

    create index(:invoices, [:recurring_invoice_id])
  end
end

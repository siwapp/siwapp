defmodule Siwapp.Repo.Migrations.AddIndexToPaidColumnAtInvoicesTable do
  use Ecto.Migration

  def up do
    create index(:invoices, [:paid], where: "paid = false")
  end

  def down do
    drop index(:invoices, [:paid])
  end
end

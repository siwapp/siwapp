defmodule Siwapp.Repo.Migrations.CreateCustomers do
  use Ecto.Migration

  def change do
    create table(:customers) do
      add :name, :string, size: 100
      add :identification, :string, size: 50
      add :hash_id, :string, size: 100
      add :email, :string, size: 100
      add :contact_person, :string, size: 100
      add :invoicing_address, :text
      add :shipping_address, :text
      add :meta_attributes, :jsonb

      timestamps()
    end

    create index(:customers, [:identification], unique: true)
    create index(:customers, [:hash_id], unique: true)
  end
end

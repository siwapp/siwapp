defmodule Siwapp.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:templates) do
      add :name, :string, size: 255
      add :template, :text
      add :print_default, :boolean, default: false
      add :email_default, :boolean, default: false
      add :subject, :string, size: 200

      timestamps()
    end
  end
end

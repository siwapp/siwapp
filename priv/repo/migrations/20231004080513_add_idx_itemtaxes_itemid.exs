defmodule Siwapp.Repo.Migrations.AddIdxItemTaxesItemId do
  use Ecto.Migration

  def up do
    execute "CREATE INDEX ON items_taxes(item_id);"
  end
end

defmodule Siwapp.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix installed.
  """

  @spec migrate :: term
  def migrate do
    Application.load(:siwapp)
    {:ok, _, _} = Ecto.Migrator.with_repo(Siwapp.Repo, &Ecto.Migrator.run(&1, :up, all: true))
  end

  @spec rollback(binary) :: term
  def rollback(version) do
    Application.load(:siwapp)
    {:ok, _, _} = Ecto.Migrator.with_repo(Siwapp.Repo, &Ecto.Migrator.run(&1, :down, to: version))
  end
end

defmodule Mix.Tasks.Siwapp.Register do
  @shortdoc "Register a new user"

  @moduledoc """
  Register a new user for a given email and password passed by the arguments.

  ## Examples

    $ mix siwapp.register "demo@example.com" "secret_pass"
  """
  use Mix.Task

  alias Siwapp.Accounts
  alias Siwapp.Accounts.User

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    validate_args!(args)

    register_user(args)
  end

  @spec register_user(list) :: :ok | no_return()
  defp register_user(args) do
    case type_of_register_user(args) do
      {:ok, user} ->
        IO.puts("User with email #{user.email} created successfully.")
        :ok

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.puts(changeset.errors)
        Mix.raise("Sorry. The user hasn't been created.")
    end
  end

  @spec validate_args!(list | term()) :: no_return()
  defp validate_args!([_, _, _]), do: :ok

  defp validate_args!([_, _]), do: :ok

  defp validate_args!(_) do
    raise_with_help("Invalid arguments")
  end

  @spec raise_with_help(binary) :: no_return()
  defp raise_with_help(msg) do
    Mix.raise("""
    #{msg}

    mix siwapp.register expects an email and a password for the user
    that is going to be registered in the Siwapp system.

    For example:
        mix siwapp.register "demo@example.com" "secret_password"
    """)
  end

  @spec type_of_register_user([binary | boolean]) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  defp type_of_register_user([email, password, admin]) do
    Accounts.register_user(%{email: email, password: password, admin: admin})
  end

  defp type_of_register_user([email, password]) do
    Accounts.register_user(%{email: email, password: password})
  end
end

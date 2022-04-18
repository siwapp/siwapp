defmodule Siwapp.Accounts.User do
  @moduledoc """
  User
  """
  use Ecto.Schema
  import Ecto.Changeset

  @email_regex Application.compile_env!(:siwapp, :email_regex)

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          email: binary | nil,
          password: binary | nil,
          hashed_password: binary | nil,
          confirmed_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          inserted_at: DateTime.t() | nil
        }

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :admin, :boolean, default: false
    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """

  @spec registration_changeset(%__MODULE__{} | Ecto.Changeset.t(), map(), list()) ::
          Ecto.Changeset.t()
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password, :admin])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  @spec validate_email(Ecto.Changeset.t(), list) :: Ecto.Changeset.t()
  defp validate_email(changeset, opts) do
    changeset
    |> maybe_validate_required(opts, :email)
    |> validate_format(:email, @email_regex, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Siwapp.Repo)
    |> unique_constraint(:email)
  end

  @spec validate_password(Ecto.Changeset.t(), keyword) :: Ecto.Changeset.t()
  defp validate_password(changeset, opts) do
    changeset
    |> maybe_validate_required(opts, :password)
    |> maybe_validate_confirmation(opts)
    |> validate_length(:password, min: 12, max: 72)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  @spec maybe_hash_password(Ecto.Changeset.t(), keyword()) :: Ecto.Changeset.t()
  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  @spec email_changeset(t(), map, list) :: Ecto.Changeset.t()
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec password_changeset(%__MODULE__{} | Ecto.Changeset.t(), map(), list()) ::
          Ecto.Changeset.t()
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  @spec confirm_changeset(t() | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def confirm_changeset(user) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  @spec valid_password?(t(), binary) :: boolean()
  def valid_password?(%Siwapp.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  @spec validate_current_password(Ecto.Changeset.t(), binary) :: Ecto.Changeset.t()
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @spec maybe_validate_required(Ecto.Changeset.t(), list, atom) :: Ecto.Changeset.t()
  defp maybe_validate_required(changeset, opts, atom) do
    required? = Keyword.get(opts, :required, true)

    if required? do
      validate_required(changeset, [atom])
    else
      changeset
    end
  end

  @spec maybe_validate_confirmation(Ecto.Changeset.t(), list) :: Ecto.Changeset.t()
  defp maybe_validate_confirmation(changeset, opts) do
    confirmation? = Keyword.get(opts, :confirmation, false)
    password_changes? = Map.has_key?(changeset.changes, :password)

    if confirmation? && password_changes? do
      validate_confirmation(changeset, :password, message: "does not match password")
    else
      changeset
    end
  end
end

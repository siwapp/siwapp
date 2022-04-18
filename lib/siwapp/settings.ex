defmodule Siwapp.Settings do
  @moduledoc """
  This module manage settings. For those with predefined keys in SettingBundle,
  which are also initialized using seeds, bundle operations can be used directly
  to change the full set of contemplated settings. Extra settings can be saved, as
  long as they have unique key, even though they won't be accessible to user using
  the form but only to developers using terminal.
  """
  import Ecto.Query

  alias Siwapp.Repo
  alias Siwapp.Settings.Setting
  alias Siwapp.Settings.SettingBundle

  @doc """
  Creates a setting given a key-value tuple (used only in seeds)
  """
  @spec create({atom | binary, binary}) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  def create({key, value}) do
    %Setting{}
    |> change({to_string(key), value})
    |> Repo.insert()
  end

  @doc """
  Returns all saved settings as a keywordlist formed by the key-value tuples
  """
  @spec list_pairs :: [] | [{atom, binary}]
  def list_pairs do
    Setting
    |> select([s], {s.key, s.value})
    |> Repo.all()
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
  end

  @doc """
  Performs the SettingBundle changeset
  """
  @spec change_bundle(SettingBundle.t(), map) :: Ecto.Changeset.t()
  def change_bundle(%SettingBundle{} = setting_bundle, attrs \\ %{}) do
    SettingBundle.changeset(setting_bundle, attrs)
  end

  @doc """
  Returns current SettingBundle (which is also useful to be changed and fill the SettingBundle form)
  """
  @spec current_bundle :: SettingBundle.t()
  def current_bundle, do: struct(SettingBundle, list_pairs())

  @doc """
  Takes a map of SettingBundle's parameters and saves each associated Setting if possible.
  Informs of the possibility to save those settings and returns the setting_bundle changeset
  """
  @spec apply_user_bundle(map) :: {:ok, Ecto.Changeset.t()} | {:error, Ecto.Changeset.t()}
  def apply_user_bundle(attrs) do
    changeset = change_bundle(current_bundle(), attrs)

    if changeset.valid? do
      changeset.changes
      |> Map.to_list()
      |> Enum.each(&act/1)

      {:ok, changeset}
    else
      {:error, %{changeset | action: :insert}}
    end
  end

  @doc """
  Returns the setting under the given key (atom or string)
  """
  @spec get(atom | binary) :: Setting.t() | nil
  def get(key),
    do: Repo.get_by(Setting, key: to_string(key))

  @doc """
  Returns the value of the setting associated to key (atom or string). Returns nil if
  this setting doesn't exist
  """
  @spec value(atom) :: binary
  def value(key) do
    case get(key) do
      nil -> nil
      setting -> setting.value
    end
  end

  @spec value(atom, atom) :: binary
  def value(key, :cache) do
    case Cachex.get(:siwapp_cache, key) do
      {:ok, nil} ->
        value = value(key)
        Cachex.put(:siwapp_cache, key, value, ttl: :timer.minutes(5))
        value

      {:ok, value} ->
        value
    end
  end

  @doc """
  Takes key-value tuple and updates the value of the Setting determined by key
  """
  @spec update({atom, any}) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  def update({key, value}) do
    Cachex.clear(:siwapp_cache)

    key
    |> get()
    |> change({to_string(key), to_string(value)})
    |> Repo.update()
  end

  @spec act(tuple) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  defp act({key, _value} = tuple) do
    if is_nil(get(key)), do: create(tuple), else: update(tuple)
  end

  @spec change(Setting.t(), {binary, binary}) :: Ecto.Changeset.t()
  defp change(%Setting{} = setting, attrs) do
    Setting.changeset(setting, adequate_attrs(attrs))
  end

  @spec adequate_attrs({binary, binary}) :: map
  defp adequate_attrs({key, value}), do: %{"key" => key, "value" => value}
end

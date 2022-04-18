defmodule Siwapp.ApiToken do
  @moduledoc false

  @signing_salt "bm9YQ9J68CJqnM3P6S62x6htopuZ4Wp5vtVOP5IdUlQcVq/d+KuAr6FEkqn3Yibg"

  # 3 hours
  @token_age_secs 3 * 3_600

  @spec sign(map) :: binary
  def sign(data) do
    Phoenix.Token.sign(SiwappWeb.Endpoint, @signing_salt, data)
  end

  @spec verify(binary) :: {:ok, map} | {:error, :unauthenticated}
  def verify(token) do
    case Phoenix.Token.verify(SiwappWeb.Endpoint, @signing_salt, token, max_age: @token_age_secs) do
      {:ok, data} -> {:ok, data}
      _error -> {:error, :unauthenticated}
    end
  end
end

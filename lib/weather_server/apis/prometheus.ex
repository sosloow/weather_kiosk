defmodule WeatherServer.Apis.Prometheus do
  @moduledoc """
  Minimal Prometheus-compatible client for querying metrics.
  """

  require Logger

  @spec query(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def query(promql, opts \\ []) when is_binary(promql) do
    params = Keyword.merge([query: promql], opts)

    case Req.get(client(), url: "/api/v1/query", params: params) do
      {:ok, %{status: 200, body: %{"status" => "success", "data" => data}}} ->
        {:ok, data}

      {:ok, %{status: 200, body: %{"status" => "error", "error" => error}}} ->
        {:error, {:query_error, error}}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("Prometheus query failed: #{inspect(reason)}")
        {:error, {:request_failed, reason}}
    end
  end

  defp client do
    base_url = Application.get_env(:weather_server, :prometheus_url, "http://127.0.0.1:8428")

    [base_url: base_url]
    |> Keyword.merge(Application.get_env(:weather_server, :prometheus_req_options, []))
    |> Req.new()
  end
end

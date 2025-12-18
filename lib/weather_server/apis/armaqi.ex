defmodule WeatherServer.Apis.Armaqi do
  @moduledoc """
  Fetches AQI data for Yerevan from Armaqi public API.
  """

  import WeatherServer.Utils.Weather
  require Logger

  @type aggregate :: %{
          pm2_5: float(),
          aqi: pos_integer(),
          raw_aqi: integer(),
          label: String.t(),
          source: String.t()
        }

  @base_url "https://api.armaqi.org/api/public"
  @default_params [type: "hour"]
  @place_id 1

  @spec fetch() :: {:ok, aggregate()} | {:error, :armaqi_failed}
  def fetch do
    client =
      [base_url: @base_url]
      |> Keyword.merge(Application.get_env(:weather_server, :armaqi_req_options, []))
      |> Req.new()

    with {:ok, entries} <- fetch_entries(client),
         {:ok, latest} <- latest_entry(entries),
         {:ok, aggregate} <- build_result(latest) do
      {:ok, aggregate}
    else
      error ->
        Logger.error("Armaqi fetch failed: #{inspect(error)}")
        {:error, :armaqi_failed}
    end
  end

  defp fetch_entries(client) do
    case Req.get(client, url: "/places/#{@place_id}", params: @default_params) do
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  defp latest_entry(entries) do
    entries
    |> Enum.reduce([], fn entry, acc ->
      case normalize_timestamp(entry) do
        {:ok, dt} ->
          pm25 = entry["pm25"]
          aqi = entry["aqi"]

          if is_number(pm25) and is_number(aqi) do
            [%{entry: entry, dt: dt} | acc]
          else
            acc
          end

        {:error, _} ->
          acc
      end
    end)
    |> Enum.max_by(&DateTime.to_unix(&1.dt, :microsecond), fn -> nil end)
    |> case do
      nil -> {:error, :no_valid_entries}
      %{entry: entry} -> {:ok, entry}
    end
  end

  defp normalize_timestamp(%{"last_update" => ts}) when is_binary(ts), do: parse_ts(ts)
  defp normalize_timestamp(%{"period_start" => ts}) when is_binary(ts), do: parse_ts(ts)

  defp normalize_timestamp(_), do: {:error, :invalid_timestamp}

  defp parse_ts(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_result(entry) do
    pm25 = entry["pm25"]
    aqi = entry["aqi"]

    if is_number(pm25) and is_number(aqi) do
      {:ok,
       %{
         pm2_5: Float.round(pm25, 1),
         aqi: aqi_to_ui_index(round(aqi)),
         raw_aqi: round(aqi),
         label: "Yerevan",
         source: "Armaqi"
       }}
    else
      {:error, :invalid_entry}
    end
  end
end

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
          source: String.t(),
          history: [map()]
        }

  @base_url "https://api.armaqi.org/api/public"
  @default_params [type: "hour"]
  @place_id 1

  @history_limit 24

  @spec fetch() :: {:ok, aggregate()} | {:error, :armaqi_failed}
  def fetch do
    client =
      [base_url: @base_url]
      |> Keyword.merge(Application.get_env(:weather_server, :armaqi_req_options, []))
      |> Req.new()

    with {:ok, entries} <- fetch_entries(client) do
      current =
        Enum.max_by(entries, &DateTime.to_unix(&1.period_start, :microsecond), fn -> nil end)

      {:ok, Map.put(current, :history, Enum.slice(entries, 0, @history_limit))}
    else
      error ->
        Logger.error("Armaqi fetch failed: #{inspect(error)}")
        {:error, :armaqi_failed}
    end
  end

  defp fetch_entries(client) do
    case Req.get(client, url: "/places/#{@place_id}", params: @default_params) do
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        {:ok,
         Enum.flat_map(body, fn item ->
           case normalize_entry(item) do
             {:ok, entry} -> [entry]
             {:error, _} -> []
           end
         end)}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  defp normalize_entry(entry) do
    with {:ok, last_update} <- parse_ts(entry["last_update"]),
         {:ok, period_start} <- parse_ts(entry["period_start"]) do
      pm25 = if is_float(entry["pm25"]), do: Float.round(entry["pm25"], 1), else: 0
      aqi = entry["aqi"]

      {:ok,
       %{
         pm2_5: pm25,
         aqi: aqi_to_ui_index(round(aqi)),
         raw_aqi: round(aqi),
         last_update: last_update,
         period_start: period_start,
         label: "Yerevan",
         source: "Armaqi"
       }}
    else
      error -> error
    end
  end

  defp parse_ts(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, datetime, _offset} -> {:ok, datetime}
      {:error, reason} -> {:error, reason}
    end
  end
end

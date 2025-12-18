defmodule WeatherServer.Apis.OpenAQ do
  @moduledoc """
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

  @type location :: %{
          id: integer(),
          sensor_id: integer(),
          last_date: DateTime.t(),
          distance: float()
        }

  @base_url "https://api.openaq.org/v3"

  @rate_limit_status 429
  @req_timeout 10_000

  @pm25_id 2

  @lat 40.173081
  @lon 44.512322
  @radius 3000

  @location_limit 100
  @cutoff_period_hours 24

  @max_stations 30

  @spec fetch() :: {:ok, aggregate()} | {:error, :openaq_failed}
  def fetch do
    api_key = System.get_env("OPENAQ_API_KEY")
    headers = [{"X-API-Key", api_key}]

    client =
      [
        base_url: @base_url,
        headers: headers
      ]
      |> Keyword.merge(Application.get_env(:weather_server, :openaq_req_options, []))
      |> Req.new()

    with {:ok, locations} <- fetch_locations(client),
         {:ok, readings} <- fetch_readings_parallel(client, locations) do
      calculate_aggregate(readings)
    else
      error ->
        Logger.error("OpenAQ Failed: #{inspect(error)}")
        {:error, :openaq_failed}
    end
  end

  @spec fetch_locations(Req.Request.t()) ::
          {:ok, [location()]}
          | {:error, :rate_limit | :location_fetch_error}
  defp fetch_locations(client) do
    params = [
      coordinates: "#{@lat},#{@lon}",
      radius: @radius,
      limit: @location_limit,
      parameters_id: @pm25_id
    ]

    cutoff_date =
      Application.get_env(:weather_server, :time_module).now()
      |> DateTime.add(-@cutoff_period_hours, :hour)

    case Req.get(client, url: "/locations", params: params) do
      {:ok, %{status: 200, body: %{"results" => results}}} ->
        candidates =
          results
          |> Enum.reduce([], fn location, acc ->
            case normalize_location(location) do
              {:ok, normalized} ->
                if DateTime.after?(normalized.last_date, cutoff_date) do
                  [normalized | acc]
                else
                  acc
                end

              {:error, _reason} ->
                acc
            end
          end)
          |> Enum.sort(&(&1.distance < &2.distance))
          |> Enum.take(@max_stations)

        {:ok, candidates}

      {:ok, %{status: @rate_limit_status}} ->
        {:error, :rate_limit}

      _ ->
        {:error, :location_fetch_error}
    end
  end

  @spec fetch_readings_parallel(Req.Request.t(), [location()]) ::
          {:ok, [number()]} | {:error, :no_valid_readings}
  defp fetch_readings_parallel(client, locations) do
    readings =
      locations
      |> Task.async_stream(
        fn loc ->
          fetch_single_station(client, loc)
        end,
        max_concurrency: @max_stations,
        timeout: @req_timeout
      )
      |> Enum.reduce([], fn
        {:ok, {:ok, val}}, acc -> [val | acc]
        _, acc -> acc
      end)

    if Enum.empty?(readings) do
      {:error, :no_valid_readings}
    else
      {:ok, readings}
    end
  end

  @spec fetch_single_station(Req.Request.t(), location()) ::
          {:ok, number()} | {:error, :no_pm25_data | :fetch_failed}
  defp fetch_single_station(client, location) do
    case Req.get(client, url: "/locations/#{location.id}/latest") do
      {:ok, %{status: 200, body: %{"results" => results}}} ->
        reading =
          Enum.find(results, fn r ->
            r["sensorsId"] == location.sensor_id and r["value"] > 0
          end) || Enum.at(results, 0)

        case reading do
          nil -> {:error, :no_pm25_data}
          r -> {:ok, r["value"]}
        end

      _ ->
        {:error, :fetch_failed}
    end
  end

  @spec calculate_aggregate([number()]) :: {:ok, aggregate()}
  defp calculate_aggregate(values) do
    avg = Enum.sum(values) / length(values)
    aqi = calculate_aqi(avg)

    result = %{
      pm2_5: Float.round(avg, 1),
      aqi: aqi_to_ui_index(aqi),
      raw_aqi: aqi,
      label: "City Avg",
      source: "#{length(values)} Sensors"
    }

    {:ok, result}
  end

  @spec normalize_location(map()) :: {:ok, location()} | {:error, atom()}
  defp normalize_location(loc) do
    with %{"sensors" => sensors} <- loc,
         %{"id" => sensor_id} <-
           Enum.find(sensors, fn s ->
             get_in(s, ["parameter", "id"]) == @pm25_id
           end),
         {:ok, last_date, _offset} <- get_last_date(loc) do
      {:ok,
       %{
         id: loc["id"],
         sensor_id: sensor_id,
         last_date: last_date,
         distance: loc["distance"]
       }}
    else
      _ -> {:error, :invalid_location}
    end
  end

  defp get_last_date(%{"datetimeLast" => %{"utc" => utc}}),
    do: DateTime.from_iso8601(utc)

  defp get_last_date(_), do: {:error, :missing_last_date}
end

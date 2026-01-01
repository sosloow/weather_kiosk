defmodule WeatherServer.Apis.WeatherApi do
  @moduledoc """
  Fetches weather data.
  """

  alias WeatherServer.Utils

  defmodule WeatherData do
    @type current :: %{
            is_day: integer(),
            temp_c: integer(),
            feelslike_c: integer(),
            condition_text: String.t(),
            icon: String.t(),
            humidity: integer(),
            wind_kph: integer(),
            pressure_mb: integer(),
            air_quality: %{aqi: integer(), pm2_5: number()}
          }

    @type forecast_day :: %{
            date: Date.t(),
            max_temp: integer(),
            min_temp: integer(),
            avghumidity: integer(),
            maxwind_kph: integer(),
            icon: String.t()
          }

    @type hourly_forecast :: %{
            time: Time.t(),
            temp_c: integer(),
            condition_text: String.t(),
            icon: String.t(),
            humidity: integer(),
            wind_kph: integer(),
            pressure_mb: integer(),
            precip_mm: number(),
            precip_chance: integer()
          }

    @type astro :: %{
            sunrise_at: Time.t(),
            sunset_at: Time.t(),
            moonrise_at: Time.t(),
            moonset_at: Time.t(),
            moon_phase: String.t(),
            is_moon_up: boolean(),
            is_sun_up: boolean()
          }

    @type t :: %__MODULE__{
            location: map(),
            current: current(),
            forecast: [forecast_day()],
            astro: astro(),
            hourly_forecast: [hourly_forecast()],
            hourly_forecast_condensed: [hourly_forecast()],
            last_updated: DateTime.t()
          }

    defstruct [
      :location,
      :current,
      :forecast,
      :astro,
      :hourly_forecast,
      :hourly_forecast_condensed,
      :last_updated
    ]
  end

  @spec fetch(String.t()) :: {:ok, WeatherData.t()} | {:error, String.t()}
  def fetch(city) do
    api_key = get_api_key()
    params = [key: api_key, q: city, days: 3, aqi: "no", alerts: "no"]

    client =
      [base_url: "https://api.weatherapi.com/v1"]
      |> Keyword.merge(Application.get_env(:weather_server, :weatherapi_req_options, []))
      |> Req.new()

    client
    |> Req.get(url: "/forecast.json", params: params)
    |> handle_response()
  end

  defp handle_response(
         {:ok,
          %Req.Response{
            status: 200,
            body: %{"forecast" => %{"forecastday" => [current_forecast_day | _]}} = body
          }}
       ) do
    hourly_forecast = normalize_hourly_forecast(current_forecast_day["hour"])

    weather = %WeatherData{
      location: body["location"],
      current: normalize_current(body["current"]),
      forecast: normalize_forecast(body["forecast"]),
      astro: normalize_astro(current_forecast_day["astro"]),
      hourly_forecast: hourly_forecast,
      hourly_forecast_condensed: condense_hourly_forecast(hourly_forecast),
      last_updated: DateTime.utc_now()
    }

    {:ok, weather}
  end

  defp handle_response({:ok, %Req.Response{status: 200}}),
    do: {:error, "Invalid response"}

  defp handle_response({:ok, %{status: status}}), do: {:error, "HTTP #{status}"}
  defp handle_response({:error, _}), do: {:error, "Network Error"}

  defp normalize_current(data) do
    %{
      is_day: data["is_day"],
      temp_c: round(data["temp_c"]),
      feelslike_c: round(data["feelslike_c"]),
      condition_text: data["condition"]["text"],
      icon: build_icon_path(icon_path(data["condition"]["code"], data["is_day"])),
      humidity: data["humidity"],
      wind_kph: round(data["wind_kph"]),
      pressure_mb: round(data["pressure_mb"]),
      air_quality: normalize_air_quality(data["air_quality"])
    }
  end

  defp normalize_air_quality(data) do
    %{
      aqi: data["us-epa-index"],
      pm2_5: data["pm2_5"]
    }
  end

  defp normalize_astro(data) do
    %{
      sunrise_at: Utils.Time.parse_time_12h!(data["sunrise"]),
      sunset_at: Utils.Time.parse_time_12h!(data["sunset"]),
      moonrise_at: Utils.Time.parse_time_12h!(data["moonrise"]),
      moonset_at: Utils.Time.parse_time_12h!(data["moonset"]),
      moon_phase: data["moon_phase"],
      is_moon_up: data["is_moon_up"] == 1,
      is_sun_up: data["is_sun_up"] == 1
    }
  end

  defp normalize_forecast(data) do
    get_in(data, ["forecastday"])
    |> Enum.map(fn day ->
      %{
        date: Date.from_iso8601!(day["date"]),
        max_temp: round(day["day"]["maxtemp_c"]),
        min_temp: round(day["day"]["mintemp_c"]),
        avghumidity: round(day["day"]["avghumidity"]),
        maxwind_kph: round(day["day"]["maxwind_kph"]),
        icon: build_icon_path(icon_path(day["day"]["condition"]["code"], 1))
      }
    end)
  end

  defp normalize_hourly_forecast(data) do
    Enum.map(data, fn hour ->
      [_, time_part] = String.split(hour["time"], " ")
      [hour_str, minute_str] = String.split(time_part, ":")
      hour_val = String.to_integer(hour_str)
      minute_val = String.to_integer(minute_str)

      %{
        time: Time.new!(hour_val, minute_val, 0),
        temp_c: round(hour["temp_c"]),
        condition_text: hour["condition"]["text"],
        icon: build_icon_path(icon_path(hour["condition"]["code"], hour["is_day"])),
        humidity: hour["humidity"],
        wind_kph: round(hour["wind_kph"]),
        pressure_mb: round(hour["pressure_mb"]),
        precip_mm: hour["precip_mm"],
        precip_chance: max(hour["chance_of_rain"], hour["chance_of_snow"])
      }
    end)
  end

  defp condense_hourly_forecast(hours) do
    hours
    |> Enum.take(24)
    |> Enum.chunk_every(3, 3, :discard)
    |> Enum.map(&aggregate_hour_chunk/1)
  end

  defp aggregate_hour_chunk(hours) do
    center = Enum.at(hours, 1) || List.first(hours)

    %{
      time: center.time,
      temp_c: Utils.Math.avg_round(hours, & &1.temp_c),
      condition_text: center.condition_text,
      icon: center.icon,
      humidity: Utils.Math.avg_round(hours, & &1.humidity),
      wind_kph: Utils.Math.avg_round(hours, & &1.wind_kph),
      pressure_mb: Utils.Math.avg_round(hours, & &1.pressure_mb),
      precip_mm: Utils.Math.sum_round(hours, & &1.precip_mm),
      precip_chance: Utils.Math.avg_round(hours, & &1.precip_chance)
    }
  end

  defp build_icon_path(name), do: "/images/weather/#{name}.png"

  defp icon_path(1000, 1), do: "sunny"
  defp icon_path(1000, 0), do: "sunny-night"
  defp icon_path(1003, 1), do: "partly-cloudy"
  defp icon_path(1003, 0), do: "partly-cloudy-night"
  defp icon_path(1006, _), do: "cloudy"
  defp icon_path(1009, _), do: "overcast"
  defp icon_path(1030, 1), do: "mist"
  defp icon_path(1030, 0), do: "mist-night"
  defp icon_path(1063, 1), do: "patchy-rain"
  defp icon_path(1063, 0), do: "patchy-rain-night"
  defp icon_path(1066, 1), do: "patchy-snow"
  defp icon_path(1066, 0), do: "patchy-snow-night"
  defp icon_path(1069, 1), do: "patchy-sleet"
  defp icon_path(1069, 0), do: "patchy-sleet-night"
  defp icon_path(1072, 1), do: "patchy-freezing-drizzle"
  defp icon_path(1072, 0), do: "patchy-freezing-drizzle-night"
  defp icon_path(1087, 1), do: "thundery-outbreaks"
  defp icon_path(1087, 0), do: "thundery-outbreaks-night"
  defp icon_path(1114, _), do: "blowing-snow"
  defp icon_path(1117, _), do: "blizzard"
  defp icon_path(1135, _), do: "fog"
  defp icon_path(1147, _), do: "freezing-fog"
  defp icon_path(1150, _), do: "patchy-light-drizzle"
  defp icon_path(1153, _), do: "light-drizzle"
  defp icon_path(1168, _), do: "freezing-drizzle"
  defp icon_path(1171, _), do: "heavy-freezing-drizzle"
  defp icon_path(1180, 1), do: "patchy-light-rain"
  defp icon_path(1180, 0), do: "patchy-light-rain-night"
  defp icon_path(1183, _), do: "light-rain"
  defp icon_path(1186, 1), do: "moderate-rain-at-times"
  defp icon_path(1186, 0), do: "moderate-rain-at-times-night"
  defp icon_path(1189, _), do: "moderate-rain"
  defp icon_path(1192, 1), do: "heavy-rain-at-times"
  defp icon_path(1192, 0), do: "heavy-rain-at-times-night"
  defp icon_path(1195, _), do: "heavy-rain"
  defp icon_path(1198, _), do: "light-freezing-rain"
  defp icon_path(1201, _), do: "moderate-or-heavy-freezing-rain"
  defp icon_path(1204, _), do: "light-sleet"
  defp icon_path(1207, _), do: "moderate-or-heavy-sleet"
  defp icon_path(1210, 1), do: "patchy-light-snow"
  defp icon_path(1210, 0), do: "patchy-light-snow-night"
  defp icon_path(1213, _), do: "light-snow"
  defp icon_path(1216, 1), do: "patchy-moderate-snow"
  defp icon_path(1216, 0), do: "patchy-moderate-snow-night"
  defp icon_path(1219, _), do: "moderate-snow"
  defp icon_path(1222, 1), do: "patchy-heavy-snow"
  defp icon_path(1222, 0), do: "patchy-heavy-snow-night"
  defp icon_path(1225, _), do: "heavy-snow"
  defp icon_path(1237, _), do: "ice-pellets"
  defp icon_path(1240, _), do: "light-rain-shower"
  defp icon_path(1243, _), do: "moderate-or-heavy-rain-shower"
  defp icon_path(1246, _), do: "torrential-rain-shower"
  defp icon_path(1249, _), do: "light-sleet-showers"
  defp icon_path(1252, _), do: "moderate-or-heavy-sleet-showers"
  defp icon_path(1255, _), do: "light-snow-showers"
  defp icon_path(1258, _), do: "moderate-or-heavy-snow-showers"
  defp icon_path(1261, _), do: "light-showers-of-ice-pellets"
  defp icon_path(1264, _), do: "moderate-or-heavy-showers-of-ice-pellets"
  defp icon_path(1273, 1), do: "patchy-light-rain-with-thunder"
  defp icon_path(1273, 0), do: "patchy-light-rain-with-thunder-night"
  defp icon_path(1276, _), do: "moderate-or-heavy-rain-with-thunder"
  defp icon_path(1279, 1), do: "patchy-light-snow-with-thunder"
  defp icon_path(1279, 0), do: "patchy-light-snow-with-thunder-night"
  defp icon_path(1282, _), do: "moderate-or-heavy-snow-with-thunder"
  defp icon_path(_, 1), do: "sunny"
  defp icon_path(_, 0), do: "sunny-night"

  defp get_api_key, do: System.get_env("WEATHER_API_KEY")
end

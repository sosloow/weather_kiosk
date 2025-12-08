defmodule WeatherServer.Apis.WeatherApi do
  @moduledoc """
  Fetches weather data.
  """

  defmodule WeatherData do
    defstruct [:location, :current, :forecast, :last_updated]
  end

  def fetch(city) do
    api_key = get_api_key()
    params = [key: api_key, q: city, days: 3, aqi: "no", alerts: "no"]

    Req.new(base_url: "https://api.weatherapi.com/v1")
    |> Req.get(url: "/forecast.json", params: params)
    |> handle_response()
  end

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}) do
    weather = %WeatherData{
      location: body["location"],
      current: normalize_current(body["current"]),
      forecast: normalize_forecast(body["forecast"]),
      last_updated: DateTime.utc_now()
    }

    {:ok, weather}
  end

  defp handle_response({:ok, %{status: status}}), do: {:error, "HTTP #{status}"}
  defp handle_response({:error, _}), do: {:error, "Network Error"}

  defp normalize_current(data) do
    %{
      temp_c: round(data["temp_c"]),
      feelslike_c: round(data["feelslike_c"]),
      condition_text: data["condition"]["text"],
      icon: icon_path(data["condition"]["code"]),
      humidity: data["humidity"],
      wind_kph: round(data["wind_kph"]),
      pressure_mb: round(data["pressure_mb"]),
      uv: round(data["uv"])
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
        icon: icon_path(day["day"]["condition"]["code"])
      }
    end)
  end

  defp icon_path(1000), do: "assets/images/sunny.png"
  defp icon_path(code) when code in [1003], do: "assets/images/partly-cloudy.png"

  defp icon_path(code) when code in [1006, 1009], do: "assets/images/cloudy.png"

  defp icon_path(code)
       when code in [
              1063,
              1183,
              1186,
              1189,
              1192,
              1195,
              1201,
              1204,
              1207,
              1240,
              1243,
              1246
            ],
       do: "assets/images/rain.png"

  defp icon_path(code)
       when code in [
              1066,
              1114,
              1117,
              1210,
              1213,
              1216,
              1219,
              1222,
              1225,
              1237,
              1252,
              1255,
              1258
            ],
       do: "assets/images/snow.png"

  defp icon_path(code)
       when code in [
              1087,
              1273,
              1276,
              1279,
              1282
            ],
       do: "assets/images/thunderstorm.png"

  defp icon_path(code) when code in [1135, 1147], do: "assets/images/fog.png"

  defp icon_path(_), do: "assets/images/cloudy.png"

  defp get_api_key, do: System.get_env("WEATHER_API_KEY")
end

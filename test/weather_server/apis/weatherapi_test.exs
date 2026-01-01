defmodule WeatherServer.Apis.WeatherApiTest do
  use WeatherServer.DataCase, async: true

  alias WeatherServer.Apis.WeatherApi

  @forecast_fixture File.read!("test/fixtures/weatherapi/forecast.json")

  setup do
    original_key = System.get_env("WEATHER_API_KEY")
    System.put_env("WEATHER_API_KEY", "test-key")

    on_exit(fn ->
      case original_key do
        nil -> System.delete_env("WEATHER_API_KEY")
        _ -> System.put_env("WEATHER_API_KEY", original_key)
      end
    end)

    :ok
  end

  setup do
    Req.Test.stub(WeatherApi, fn conn ->
      case conn.request_path do
        "/v1/forecast.json" ->
          Req.Test.json(conn, Jason.decode!(@forecast_fixture))

        _ ->
          conn |> Plug.Conn.put_status(404) |> Req.Test.json(%{})
      end
    end)

    :ok
  end

  describe "fetch/1" do
    test "returns {:ok, WeatherData.t} with normalized fields" do
      assert {:ok, %WeatherApi.WeatherData{} = data} = WeatherApi.fetch("Yerevan")

      assert %DateTime{} = data.last_updated
      assert is_map(data.location)
      assert is_map(data.current)

      assert length(data.forecast) == 3

      assert Enum.all?(data.forecast, fn day ->
               match?(%{date: %Date{}, icon: _}, day)
             end)

      assert length(data.hourly_forecast) == 24
      assert Enum.all?(data.hourly_forecast, fn hour -> match?(%{time: %Time{}}, hour) end)
    end

    test "returns normalized values for a successful response" do
      assert {:ok, %WeatherApi.WeatherData{} = data} = WeatherApi.fetch("Yerevan")

      assert data.location["name"] == "Yerevan"

      assert %{
               is_day: 0,
               temp_c: 5,
               feelslike_c: 5,
               condition_text: "Mist",
               icon: "/images/weather/mist-night.png",
               humidity: 93,
               wind_kph: 4,
               pressure_mb: 1016,
               air_quality: %{aqi: 1, pm2_5: 10.25}
             } = data.current

      first_day = Enum.at(data.forecast, 0)

      assert %{
               date: ~D[2025-12-10],
               max_temp: 9,
               min_temp: 5,
               avghumidity: 78,
               maxwind_kph: 9,
               icon: "/images/weather/moderate-rain.png"
             } = first_day

      first_hour = Enum.at(data.hourly_forecast, 0)

      assert %{
               time: %Time{},
               temp_c: 7,
               condition_text: "Patchy rain nearby",
               icon: "/images/weather/patchy-rain-night.png",
               humidity: 83,
               wind_kph: 4,
               pressure_mb: 1019,
               precip_mm: 0.02,
               precip_chance: 87
             } = first_hour
    end

    test "returns {:error, reason} on non-200 responses" do
      Req.Test.stub(WeatherApi, fn conn ->
        conn |> Plug.Conn.put_status(500) |> Req.Test.json(%{})
      end)

      assert {:error, "HTTP 500"} = WeatherApi.fetch("Nowhere")
    end
  end
end

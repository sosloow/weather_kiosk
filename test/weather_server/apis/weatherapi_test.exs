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
    end

    test "returns {:error, reason} on non-200 responses" do
      Req.Test.stub(WeatherApi, fn conn ->
        conn |> Plug.Conn.put_status(500) |> Req.Test.json(%{})
      end)

      assert {:error, "HTTP 500"} = WeatherApi.fetch("Nowhere")
    end
  end
end

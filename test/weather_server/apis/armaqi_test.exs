defmodule WeatherServer.Apis.ArmaqiTest do
  use WeatherServer.DataCase, async: true

  alias WeatherServer.Apis.Armaqi

  @fixture File.read!("test/fixtures/armaqi/location-detail-hour.json")

  setup do
    Req.Test.stub(Armaqi, fn conn ->
      case {conn.method, conn.request_path, conn.query_params} do
        {"GET", "/api/public/places/1", %{"type" => "hour"}} ->
          Req.Test.json(conn, Jason.decode!(@fixture))

        _ ->
          conn |> Plug.Conn.put_status(404) |> Req.Test.json(%{})
      end
    end)

    :ok
  end

  describe "fetch/0" do
    @tag capture_log: true
    test "returns latest entry as aggregate" do
      assert {:ok, result} = Armaqi.fetch()

      assert result.aqi == 3
      assert result.pm2_5 == 35.9
      assert result.raw_aqi == 102
      assert result.label == "Yerevan"
      assert result.source == "Armaqi"
      assert length(result.history) == 24
    end

    @tag capture_log: true
    test "handles non-200 responses" do
      Req.Test.stub(Armaqi, fn conn ->
        conn |> Plug.Conn.put_status(500) |> Req.Test.json(%{})
      end)

      assert {:error, :armaqi_failed} = Armaqi.fetch()
    end
  end
end

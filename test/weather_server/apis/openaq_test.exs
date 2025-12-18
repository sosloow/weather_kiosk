defmodule WeatherServer.Apis.OpenAQTest do
  use WeatherServer.DataCase, async: true

  import Mox

  @locations_fixture File.read!("test/fixtures/openaq/locations.json")
  @latest_fixture File.read!("test/fixtures/openaq/location-latest.json")

  setup :verify_on_exit!

  setup do
    Req.Test.stub(WeatherServer.Apis.OpenAQ, fn conn ->
      case conn.request_path do
        "/v3/locations" ->
          Req.Test.json(conn, Jason.decode!(@locations_fixture))

        "/v3/locations/" <> _ ->
          Req.Test.json(conn, Jason.decode!(@latest_fixture))
      end
    end)

    :ok
  end

  describe "fetch/0" do
    test "returns {:ok, result} on successful API calls" do
      WeatherServer.Mocks.Time
      |> expect(:now, fn -> ~U[2025-12-10 07:00:00Z] end)

      assert {:ok, _results} = WeatherServer.Apis.OpenAQ.fetch()
    end
  end
end

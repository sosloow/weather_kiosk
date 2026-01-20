defmodule WeatherServer.Apis.PrometheusTest do
  use WeatherServer.DataCase, async: true

  alias WeatherServer.Apis.HardwareMetrics
  alias WeatherServer.Apis.Prometheus
  alias WeatherServer.Settings
  alias WeatherServer.Settings.NetworkDevice

  @online_fixture File.read!("test/fixtures/prometheus/online.json")
  @cpu_fixture File.read!("test/fixtures/prometheus/cpu.json")
  @ram_fixture File.read!("test/fixtures/prometheus/ram.json")
  @uptime_fixture File.read!("test/fixtures/prometheus/uptime.json")

  setup do
    Req.Test.stub(Prometheus, fn conn ->
      conn = Plug.Conn.fetch_query_params(conn)
      query = normalize_query(conn.query_params["query"])

      response =
        cond do
          String.contains?(query, "up{job=\"node\"") ->
            Jason.decode!(@online_fixture)

          String.contains?(query, "node_cpu_seconds_total") ->
            Jason.decode!(@cpu_fixture)

          String.contains?(query, "node_memory_MemAvailable_bytes") ->
            Jason.decode!(@ram_fixture)

          String.contains?(query, "node_boot_time_seconds") ->
            Jason.decode!(@uptime_fixture)

          true ->
            %{"status" => "error", "error" => "unknown query"}
        end

      Req.Test.json(conn, response)
    end)

    :ok
  end

  describe "query/2" do
    test "returns data for a valid query" do
      assert {:ok, %{"resultType" => "vector", "result" => [result | _]}} =
               Prometheus.query("up{job=\"node\", instance=\"rp5\"}")

      assert %{"metric" => %{"instance" => "rp5"}, "value" => [_timestamp, value]} = result
      assert value == "1"
    end
  end

  describe "HardwareMetrics.fetch/0" do
    test "combines device settings with metrics" do
      device = %NetworkDevice{
        id: "rp5",
        name: "Raspberry Pi 5",
        role: "server",
        metrics_instance: "rp5"
      }

      assert {:ok, _setting} = Settings.update_devices([device])

      assert {:ok, [status]} = HardwareMetrics.fetch()
      assert status.id == "rp5"
      assert status.name == "Raspberry Pi 5"
      assert status.online == true
      assert_in_delta status.cpu_percent, 1.0333333333255865, 0.001
      assert_in_delta status.ram_percent, 21.018484965341898, 0.001
      assert_in_delta status.uptime_seconds, 2_320_544.398563862, 0.001
    end
  end

  defp normalize_query(query) when is_binary(query) do
    query
    |> String.replace(~r/\s+/, "")
  end

  defp normalize_query(_query), do: ""
end

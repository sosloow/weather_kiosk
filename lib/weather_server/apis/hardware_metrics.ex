defmodule WeatherServer.Apis.HardwareMetrics do
  @moduledoc """
  Fetches hardware monitoring data from a Prometheus-compatible API.
  """

  alias WeatherServer.Apis.Prometheus
  alias WeatherServer.Settings

  require Logger

  @type device_metrics :: %{optional(:online | :cpu | :ram | :uptime) => float() | nil}
  @type metrics_map :: %{String.t() => device_metrics()}

  @type device_status :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          role: String.t(),
          metrics_instance: String.t(),
          online: boolean(),
          cpu_percent: float() | nil,
          ram_percent: float() | nil,
          uptime_seconds: float() | nil
        }

  defstruct [
    :id,
    :name,
    :role,
    :metrics_instance,
    :online,
    :cpu_percent,
    :ram_percent,
    :uptime_seconds
  ]

  @spec fetch([device_status()] | nil) :: {:ok, [device_status()]} | {:error, term()}
  def fetch(previous_statuses \\ []) do
    devices = Settings.get_devices()

    if devices == [] do
      {:ok, []}
    else
      previous_metrics = build_previous_metrics(previous_statuses)

      case fetch_metrics(devices, previous_metrics) do
        {:ok, metrics} ->
          statuses = Enum.map(devices, &merge_device(&1, metrics))
          {:ok, statuses}

        {:error, reason} ->
          Logger.warning("Hardware metrics fetch failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp fetch_metrics(devices, previous_metrics) do
    queries =
      devices
      |> Enum.flat_map(fn device ->
        metric_queries(device)
        |> Enum.map(fn {metric, query} -> {device.id, metric, query} end)
      end)

    {metrics, errors} =
      Task.async_stream(queries, &fetch_query/1, timeout: :infinity)
      |> Enum.reduce({%{}, []}, fn
        {:ok, {device_id, metric, {:ok, value}}}, {acc, error_acc} ->
          {update_metrics(acc, device_id, metric, value), error_acc}

        {:ok, {device_id, metric, {:error, reason}}}, {acc, error_acc} ->
          fallback = get_in(previous_metrics, [device_id, metric])

          {update_metrics(acc, device_id, metric, fallback),
           [{device_id, metric, reason} | error_acc]}

        {:exit, reason}, {acc, error_acc} ->
          {acc, [{:task_exit, reason} | error_acc]}
      end)

    if errors != [] do
      Logger.warning("Hardware metrics query errors: #{inspect(errors)}")
    end

    if Enum.any?(errors, &match?({:task_exit, _}, &1)) do
      {:error, errors}
    else
      {:ok, metrics}
    end
  end

  defp metric_queries(device) do
    instance = device.metrics_instance

    [
      online: ~s|up{job="node", instance="#{instance}"}|,
      cpu:
        ~s|100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle",job="node",instance="#{instance}"}[2m])) * 100)|,
      ram:
        ~s|(1 - (node_memory_MemAvailable_bytes{job="node",instance="#{instance}"} / node_memory_MemTotal_bytes{job="node",instance="#{instance}"})) * 100|,
      uptime:
        ~s|node_time_seconds{job="node",instance="#{instance}"} - node_boot_time_seconds{job="node",instance="#{instance}"}|
    ]
  end

  defp fetch_query({device_id, metric, query}) do
    case Prometheus.query(query) do
      {:ok, %{"result" => result}} ->
        {device_id, metric, {:ok, parse_vector_value(result)}}

      {:ok, _payload} ->
        {device_id, metric, {:ok, nil}}

      {:error, reason} ->
        {device_id, metric, {:error, reason}}
    end
  end

  defp parse_vector_value(result) do
    case result do
      [%{"value" => [_timestamp, value]} | _] -> parse_float(value)
      _ -> nil
    end
  end

  defp parse_float(value) when is_float(value), do: value

  defp parse_float(value) when is_binary(value) do
    case Float.parse(value) do
      {number, _} -> number
      :error -> nil
    end
  end

  defp parse_float(_value), do: nil

  defp update_metrics(metrics, device_id, metric, value) do
    Map.update(metrics, device_id, %{metric => value}, fn device_metrics ->
      Map.put(device_metrics, metric, value)
    end)
  end

  defp merge_device(device, metrics) do
    device_metrics = Map.get(metrics, device.id, %{})

    %__MODULE__{
      id: device.id,
      name: device.name,
      role: device.role,
      metrics_instance: device.metrics_instance,
      online: Map.get(device_metrics, :online) == 1.0,
      cpu_percent: Map.get(device_metrics, :cpu),
      ram_percent: Map.get(device_metrics, :ram),
      uptime_seconds: Map.get(device_metrics, :uptime)
    }
  end

  defp build_previous_metrics(previous_statuses) when is_list(previous_statuses) do
    Enum.reduce(previous_statuses, %{}, fn status, acc ->
      online_value = if status.online == true, do: 1.0, else: 0.0

      Map.put(acc, status.id, %{
        online: online_value,
        cpu: status.cpu_percent,
        ram: status.ram_percent,
        uptime: status.uptime_seconds
      })
    end)
  end

  defp build_previous_metrics(_previous_statuses), do: %{}
end

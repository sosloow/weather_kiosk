defmodule WeatherServer.Cache do
  use GenServer

  alias WeatherServer.Apis.Armaqi
  alias WeatherServer.Apis.HardwareMetrics
  alias WeatherServer.Apis.WeatherApi

  @weather_topic "dashboard_weather_updates"
  @aqi_topic "dashboard_aqi_updates"
  @metrics_topic "dashboard_metrics_updates"

  @weather_refresh_period 15 * 60 * 1000
  @aqi_refresh_period 30 * 60 * 1000
  @metrics_refresh_period 60 * 1000

  @type payload :: %{
          weather: WeatherApi.WeatherData.t() | nil,
          aqi: Armaqi.aggregate() | nil,
          metrics: [HardwareMetrics.device_status()] | nil
        }
  @type state :: payload()

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec get_weather() :: {:ok, WeatherApi.WeatherData.t()} | {:error, term()}
  def get_weather do
    GenServer.call(__MODULE__, :get_weather)
  end

  @spec get_aqi() :: {:ok, Armaqi.aggregate()} | {:error, term()}
  def get_aqi do
    GenServer.call(__MODULE__, :get_aqi)
  end

  @spec get_metrics() :: {:ok, [HardwareMetrics.device_status()]} | {:error, term()}
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @spec subscribe_weather() :: :ok | {:error, term()}
  def subscribe_weather do
    Phoenix.PubSub.subscribe(WeatherServer.PubSub, @weather_topic)
  end

  @spec subscribe_aqi() :: :ok | {:error, term()}
  def subscribe_aqi do
    Phoenix.PubSub.subscribe(WeatherServer.PubSub, @aqi_topic)
  end

  @spec subscribe_metrics() :: :ok | {:error, term()}
  def subscribe_metrics do
    Phoenix.PubSub.subscribe(WeatherServer.PubSub, @metrics_topic)
  end

  @impl true
  def init(_) do
    schedule_weather_fetch()
    schedule_aqi_fetch()
    schedule_metrics_fetch()

    if immediate_ticks?() do
      send(self(), :weather_tick)
      send(self(), :aqi_tick)
      send(self(), :metrics_tick)
    end

    {:ok, %{weather: nil, aqi: nil, metrics: nil}}
  end

  @impl true
  def handle_info(:weather_tick, state) do
    schedule_weather_fetch()

    case fetch_weather() do
      {:ok, weather_data} ->
        Phoenix.PubSub.broadcast(
          WeatherServer.PubSub,
          @weather_topic,
          {:weather_update, weather_data}
        )

        {:noreply, %{state | weather: weather_data}}

      {:error, _} ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:aqi_tick, state) do
    schedule_aqi_fetch()

    case fetch_aqi() do
      {:ok, aqi_data} ->
        Phoenix.PubSub.broadcast(WeatherServer.PubSub, @aqi_topic, {:aqi_update, aqi_data})
        {:noreply, %{state | aqi: aqi_data}}

      {:error, _} ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:metrics_tick, state) do
    schedule_metrics_fetch()

    case fetch_metrics(state.metrics) do
      {:ok, metrics_data} ->
        Phoenix.PubSub.broadcast(
          WeatherServer.PubSub,
          @metrics_topic,
          {:metrics_update, metrics_data}
        )

        {:noreply, %{state | metrics: metrics_data}}

      {:error, _} ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_weather, _from, %{weather: %WeatherApi.WeatherData{} = weather} = state) do
    {:reply, {:ok, weather}, state}
  end

  def handle_call(:get_weather, _from, state) do
    case fetch_weather() do
      {:ok, weather_data} ->
        {:reply, {:ok, weather_data}, %{state | weather: weather_data}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_aqi, _from, %{aqi: %{} = aqi} = state) do
    {:reply, {:ok, aqi}, state}
  end

  def handle_call(:get_aqi, _from, state) do
    case fetch_aqi() do
      {:ok, aqi_data} ->
        {:reply, {:ok, aqi_data}, %{state | aqi: aqi_data}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_metrics, _from, %{metrics: metrics} = state)
      when is_list(metrics) do
    {:reply, {:ok, metrics}, state}
  end

  def handle_call(:get_metrics, _from, state) do
    case fetch_metrics(state.metrics) do
      {:ok, metrics_data} ->
        {:reply, {:ok, metrics_data}, %{state | metrics: metrics_data}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp schedule_weather_fetch,
    do: Process.send_after(self(), :weather_tick, @weather_refresh_period)

  defp schedule_aqi_fetch, do: Process.send_after(self(), :aqi_tick, @aqi_refresh_period)

  defp schedule_metrics_fetch,
    do: Process.send_after(self(), :metrics_tick, @metrics_refresh_period)

  defp fetch_weather do
    WeatherApi.fetch("Yerevan")
  end

  defp fetch_aqi do
    Armaqi.fetch()
  end

  defp fetch_metrics(previous_metrics) do
    HardwareMetrics.fetch(previous_metrics)
  end

  defp immediate_ticks? do
    Application.get_env(:weather_server, :cache_immediate_ticks, true)
  end
end

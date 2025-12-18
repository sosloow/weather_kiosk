defmodule WeatherServer.Cache do
  use GenServer
  # alias WeatherServer.Apis.OpenAQ
  alias WeatherServer.Apis.Armaqi
  alias WeatherServer.Apis.WeatherApi

  @topic "dashboard_updates"

  @type payload :: %{
          weather: WeatherApi.WeatherData.t(),
          aqi: Armaqi.aggregate()
        }

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @spec get_current_data() :: {:ok, payload()} | {:error, term()}
  def get_current_data do
    GenServer.call(__MODULE__, :get_data)
  end

  @spec subscribe() :: :ok | {:error, term()}
  def subscribe do
    Phoenix.PubSub.subscribe(WeatherServer.PubSub, @topic)
  end

  @impl true
  def init(_) do
    schedule_next_fetch()
    {:ok, nil}
  end

  @impl true
  def handle_info(:tick, state) do
    schedule_next_fetch()

    case fetch_external_api() do
      {:ok, new_data} ->
        Phoenix.PubSub.broadcast(WeatherServer.PubSub, @topic, {:weather_update, new_data})
        {:noreply, new_data}

      {:error, _} ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call(:get_data, _from, current_state) do
    if valid_data?(current_state) do
      {:reply, {:ok, current_state}, current_state}
    else
      case fetch_external_api() do
        {:ok, new_data} ->
          {:reply, {:ok, new_data}, new_data}

        {:error, reason} ->
          {:reply, {:error, reason}, nil}
      end
    end
  end

  defp schedule_next_fetch, do: Process.send_after(self(), :tick, 15 * 60 * 1000)

  @spec fetch_external_api() :: {:ok, payload()} | {:error, term()}
  defp fetch_external_api do
    with {:ok, weather_data} <- WeatherApi.fetch("Yerevan"),
         {:ok, aqi_data} <- Armaqi.fetch() do
      {:ok, %{weather: weather_data, aqi: aqi_data}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp valid_data?(nil), do: false
  defp valid_data?({:error, _}), do: false
  defp valid_data?(_), do: true
end

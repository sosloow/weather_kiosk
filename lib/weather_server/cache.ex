defmodule WeatherServer.Cache do
  use GenServer
  alias WeatherServer.Apis.WeatherApi

  @topic "dashboard_updates"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_current_data do
    GenServer.call(__MODULE__, :get_data)
  end

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

  defp fetch_external_api do
    WeatherApi.fetch("Yerevan")
  end

  defp valid_data?(nil), do: false
  defp valid_data?({:error, _}), do: false
  defp valid_data?(_), do: true
end

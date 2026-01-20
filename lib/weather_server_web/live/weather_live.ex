defmodule WeatherServerWeb.WeatherLive do
  use WeatherServerWeb, :live_view

  alias WeatherServer.Cache
  alias WeatherServer.Settings

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Cache.subscribe_weather()
      Cache.subscribe_aqi()
    end

    theme = Settings.get_theme()

    socket =
      socket
      |> assign(:theme, theme)
      |> assign(:active_nav, :weather)
      |> assign(:page_title, "Weather Dashboard")

    socket = assign_weather(socket, Cache.get_weather())
    socket = assign_aqi(socket, Cache.get_aqi())

    {:ok, socket}
  end

  @impl true
  def handle_info({:weather_update, weather_data}, socket) do
    {:noreply, assign_weather(socket, {:ok, weather_data})}
  end

  def handle_info({:aqi_update, aqi_data}, socket) do
    {:noreply, assign_aqi(socket, {:ok, aqi_data})}
  end

  defp assign_weather(socket, {:ok, weather_data}) do
    socket
    |> assign(:weather, weather_data)
    |> assign(
      :header_title,
      "#{weather_data.location["name"]}, #{weather_data.location["country"]}"
    )
    |> assign(
      :hourly_forecast_condensed,
      Map.get(weather_data, :hourly_forecast_condensed, weather_data.hourly_forecast)
    )
  end

  defp assign_weather(socket, {:error, reason}) do
    IO.inspect(reason)
    socket
  end

  defp assign_aqi(socket, {:ok, aqi_data}) do
    assign(socket, :aqi, aqi_data)
  end

  defp assign_aqi(socket, {:error, reason}) do
    IO.inspect(reason)
    socket
  end
end

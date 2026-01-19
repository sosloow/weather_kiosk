defmodule WeatherServerWeb.WeatherLive do
  use WeatherServerWeb, :live_view
  alias WeatherServer.Cache
  alias WeatherServer.Settings

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Cache.subscribe()

    theme = Settings.get_theme()

    socket =
      socket
      |> assign(:theme, theme)
      |> assign(:active_nav, :weather)

    with {:ok, %{weather: weather_data, aqi: aqi_data}} <- Cache.get_current_data() do
      socket =
        socket
        |> assign(:weather, weather_data)
        |> assign(:aqi, aqi_data)
        |> assign(
          :header_title,
          "#{weather_data.location["name"]}, #{weather_data.location["country"]}"
        )
        |> assign(
          :hourly_forecast_condensed,
          Map.get(weather_data, :hourly_forecast_condensed, weather_data.hourly_forecast)
        )
        |> assign(:page_title, "Weather Dashboard")

      {:ok, socket}
    else
      {:error, reason} ->
        IO.inspect(reason)
        {:ok, socket}
    end
  end

  @impl true
  def handle_info({:weather_update, %{weather: weather_data, aqi: aqi_data}}, socket) do
    socket =
      socket
      |> assign(:weather, weather_data)
      |> assign(:aqi, aqi_data)
      |> assign(
        :header_title,
        "#{weather_data.location["name"]}, #{weather_data.location["country"]}"
      )
      |> assign(
        :hourly_forecast_condensed,
        Map.get(weather_data, :hourly_forecast_condensed, weather_data.hourly_forecast)
      )

    {:noreply, socket}
  end
end

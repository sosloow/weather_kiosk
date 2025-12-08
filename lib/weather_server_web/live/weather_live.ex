defmodule WeatherServerWeb.WeatherLive do
  use WeatherServerWeb, :live_view
  alias WeatherServer.Cache

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Cache.subscribe()

    with {:ok, weather_data} <- Cache.get_current_data() do
      socket =
        socket
        |> assign(:weather, weather_data)
        |> assign(
          :header_title,
          "#{weather_data.location["name"]}, #{weather_data.location["country"]}"
        )
        |> assign(:page_title, "Weather Dashboard")

      {:ok, socket}
    else
      {:error, _reason} -> {:ok, socket}
    end
  end
end

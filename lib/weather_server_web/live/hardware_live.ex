defmodule WeatherServerWeb.HardwareLive do
  use WeatherServerWeb, :live_view

  alias WeatherServer.Cache
  alias WeatherServer.Settings

  @slots 8

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Cache.subscribe_metrics()

    theme = Settings.get_theme()

    socket =
      socket
      |> assign(:theme, theme)
      |> assign(:active_nav, :hardware)
      |> assign(:header_title, "Hardware")
      |> assign(:page_title, "Hardware")

    socket = assign_devices(socket, Cache.get_metrics())

    {:ok, socket}
  end

  @impl true
  def handle_info({:metrics_update, devices}, socket) do
    {:noreply, assign_devices(socket, {:ok, devices})}
  end

  defp assign_devices(socket, {:ok, devices}) do
    padded_devices = pad_devices(devices, @slots)

    socket
    |> assign(:devices, padded_devices)
    |> assign(:device_count, length(devices))
  end

  defp assign_devices(socket, {:error, reason}) do
    IO.inspect(reason)
    assign(socket, :devices, pad_devices([], @slots))
  end

  defp pad_devices(devices, slots) do
    devices
    |> Enum.take(slots)
    |> Enum.concat(List.duplicate(nil, max(slots - length(devices), 0)))
  end

  defp format_uptime(nil), do: "—"

  defp format_uptime(seconds) when is_number(seconds) do
    total_minutes = trunc(seconds / 60)
    total_hours = div(total_minutes, 60)
    days = div(total_hours, 24)
    hours = rem(total_hours, 24)
    minutes = rem(total_minutes, 60)

    if days > 0 do
      "#{pad_time(days)}:#{pad_time(hours)}:#{pad_time(minutes)}"
    else
      "#{pad_time(hours)}:#{pad_time(minutes)}"
    end
  end

  defp pad_time(value), do: String.pad_leading(Integer.to_string(value), 2, "0")
end

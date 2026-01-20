defmodule WeatherServerWeb.SettingsLive do
  use WeatherServerWeb, :live_view

  alias WeatherServer.Settings
  alias WeatherServer.Settings.NetworkDevice

  @theme_options [
    {"Light", "light"},
    {"Dark", "dark"},
    {"Cupcake", "cupcake"},
    {"Dracula", "dracula"},
    {"Abyss", "abyss"},
    {"Forest", "forest"},
    {"Dim", "dim"},
    {"Sunset", "sunset"},
    {"Night", "night"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    theme = Settings.get_theme()

    devices = Settings.get_devices()

    socket =
      socket
      |> assign(:theme, theme)
      |> assign(:active_nav, :settings)
      |> assign(:form, to_form(%{"theme" => theme}, as: :appearance))
      |> assign(:theme_options, @theme_options)
      |> assign(:devices, devices)
      |> assign(:device_errors, %{})
      |> assign(:device_role_options, NetworkDevice.roles())
      |> assign(:section, "appearance")
      |> assign(:page_title, "Settings")
      |> assign(:header_title, "Settings")

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    section = normalize_section(params["section"])
    {:noreply, assign(socket, :section, section)}
  end

  @impl true
  def handle_event("update_theme", %{"appearance" => %{"theme" => theme}}, socket) do
    {:ok, _setting} = Settings.set_theme(theme)

    socket =
      socket
      |> assign(:theme, theme)
      |> assign(:form, to_form(%{"theme" => theme}, as: :appearance))
      |> push_event("theme:update", %{theme: theme})

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_device", _params, socket) do
    devices = socket.assigns.devices ++ [NetworkDevice.empty()]

    {:noreply,
     socket
     |> assign(:devices, devices)
     |> assign(:device_errors, %{})}
  end

  @impl true
  def handle_event("remove_device", %{"index" => index}, socket) do
    devices = List.delete_at(socket.assigns.devices, String.to_integer(index))

    {:noreply,
     socket
     |> assign(:devices, devices)
     |> assign(:device_errors, %{})}
  end

  @impl true
  def handle_event("save_devices", %{"devices" => devices_params}, socket) do
    devices = devices_params_to_structs(devices_params)
    errors = Settings.validate_devices(devices)

    if errors == [] do
      case Settings.update_devices(devices) do
        {:ok, _setting} ->
          socket =
            socket
            |> assign(:devices, devices)
            |> assign(:device_errors, %{})
            |> put_flash(:info, "Network inventory updated")

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Could not save inventory")}
      end
    else
      {:noreply, assign(socket, :device_errors, format_device_errors(errors))}
    end
  end

  def handle_event("save_devices", _params, socket) do
    {:noreply, assign(socket, :device_errors, %{0 => %{id: ["Add at least one device"]}})}
  end

  defp devices_params_to_structs(devices_params) do
    devices_params
    |> Enum.sort_by(fn {index, _} -> String.to_integer(index) end)
    |> Enum.map(fn {_index, attrs} -> NetworkDevice.from_map(attrs) end)
  end

  defp format_device_errors(errors) do
    Enum.reduce(errors, %{}, fn {index, field, message}, acc ->
      Map.update(acc, index, %{field => [message]}, fn fields ->
        Map.update(fields, field, [message], fn messages ->
          [message | messages]
        end)
      end)
    end)
  end

  defp normalize_section(section) when section in ["appearance", "network"], do: section
  defp normalize_section(_section), do: "appearance"
end

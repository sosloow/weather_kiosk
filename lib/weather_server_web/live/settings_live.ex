defmodule WeatherServerWeb.SettingsLive do
  use WeatherServerWeb, :live_view

  alias WeatherServer.Settings

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

    socket =
      socket
      |> assign(:theme, theme)
      |> assign(:active_nav, :settings)
      |> assign(:form, to_form(%{"theme" => theme}, as: :appearance))
      |> assign(:theme_options, @theme_options)
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

  defp normalize_section(section) when section in ["appearance", "network"], do: section
  defp normalize_section(_section), do: "appearance"
end

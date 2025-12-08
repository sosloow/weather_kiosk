defmodule WeatherServerWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality.
  """
  use WeatherServerWeb, :html

  # 1. This line looks for "layouts/root.html.heex" and "layouts/app.html.heex"
  # and compiles them into functions automatically.
  embed_templates "layouts/*"

  # --- HELPERS (Keep these!) ---

  @doc """
  Shows the flash group. I recommend keeping this for the "Reconnecting" 
  state, which is useful for a Kiosk if Wi-Fi drops.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "optional id"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="server-error"
        kind={:error}
        title="Offline"
        phx-disconnected={JS.remove_attribute("hidden", to: ".phx-server-error #server-error")}
        phx-connected={JS.set_attribute({"hidden", ""}, to: "#server-error")}
        hidden
      >
        Attempting to reconnect...
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end

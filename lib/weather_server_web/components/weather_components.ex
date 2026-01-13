defmodule WeatherServerWeb.WeatherComponents do
  use Phoenix.Component
  import WeatherServerWeb.CoreComponents
  import WeatherServer.Utils.Weather
  import WeatherServer.Utils.Time

  defp aqi_to_label(1), do: "Clean"
  defp aqi_to_label(2), do: "Fair"
  defp aqi_to_label(3), do: "Sensitive"
  defp aqi_to_label(4), do: "Poor"
  defp aqi_to_label(5), do: "Bad"
  defp aqi_to_label(_), do: "Toxic"

  defp aqi_to_icon(1), do: "hero-shield-check"
  defp aqi_to_icon(2), do: "hero-check-circle"
  defp aqi_to_icon(3), do: "hero-exclamation-circle"
  defp aqi_to_icon(4), do: "hero-exclamation-triangle"
  defp aqi_to_icon(5), do: "hero-fire"
  defp aqi_to_icon(_), do: "hero-skull"

  defp aqi_to_text_color(1), do: "text-emerald-400"
  defp aqi_to_text_color(2), do: "text-amber-400"
  defp aqi_to_text_color(3), do: "text-orange-400"
  defp aqi_to_text_color(4), do: "text-rose-400"
  defp aqi_to_text_color(5), do: "text-fuchsia-400"
  defp aqi_to_text_color(_), do: "text-stone-400"

  defp aqi_to_bar_color(1), do: "text-emerald-400/50"
  defp aqi_to_bar_color(2), do: "text-amber-400/50"
  defp aqi_to_bar_color(3), do: "text-orange-400/50"
  defp aqi_to_bar_color(4), do: "text-rose-400/50"
  defp aqi_to_bar_color(5), do: "text-fuchsia-400/50"
  defp aqi_to_bar_color(_), do: "text-stone-400/50"

  defp aqi_to_bg_color(1), do: "bg-emerald-400/40"
  defp aqi_to_bg_color(2), do: "bg-amber-400/40"
  defp aqi_to_bg_color(3), do: "bg-orange-400/40"
  defp aqi_to_bg_color(4), do: "bg-rose-400/40"
  defp aqi_to_bg_color(5), do: "bg-fuchsia-400/40"
  defp aqi_to_bg_color(_), do: "bg-stone-400/40"

  attr :aqi, :integer, required: true
  attr :raw_aqi, :integer, required: true
  attr :pm2_5, :float, required: true
  attr :history, :list, default: []

  def aqi_section(assigns) do
    ~H"""
    <.panel>
      <div class={"flex-grow flex flex-col items-center justify-center relative p-4 gap-2 " <> aqi_to_text_color(@aqi)}>
        <div class={"absolute inset-0 opacity-10 " <> aqi_to_bg_color(@aqi)}></div>

        <div class="transition-transform duration-500 group-hover:scale-110">
          <.icon
            name={aqi_to_icon(@aqi)}
            class="w-20 h-20"
          />
        </div>

        <div class="text-center z-10">
          <h3 class="text-2xl font-black tracking-tight">
            {aqi_to_label(@aqi)}
          </h3>

          <p class="text-xs font-medium text-base-content/60 uppercase tracking-widest mt-1">
            AQI {@raw_aqi}
          </p>
        </div>
      </div>

      <div class="h-[90px] p-4 flex flex-col justify-center gap-1">
        <div class="flex justify-between items-end mb-1">
          <span class="text-xs font-bold opacity-50 uppercase">PM2.5</span>
          <span class="text-2xl font-mono font-bold leading-none">
            {@pm2_5}
          </span>
        </div>

        <% percent = min(round(@pm2_5 / 55 * 100), 100)

        bar_color =
          cond do
            @pm2_5 < 12 -> "bg-success"
            @pm2_5 < 35 -> "bg-warning"
            true -> "bg-error"
          end %>

        <div class="w-full h-2 bg-base-content/10 rounded-full overflow-hidden flex-shrink-0">
          <div
            class={"h-full transition-all duration-1000 " <> bar_color}
            style={"width: #{percent}%"}
          >
          </div>
        </div>

        <div class="text-[10px] text-right opacity-40 mt-1">µg/m³</div>
      </div>
    </.panel>
    """
  end

  defp build_hourly_aqi_bars(history) do
    entries =
      history
      |> Enum.reverse()
      |> Enum.take(24)
      |> Enum.map(fn h ->
        %{value: h.raw_aqi, time: time_from_datetime(h.period_start)}
      end)

    max_value = Enum.max(Enum.map(entries, & &1.value) ++ [1])

    Enum.map(entries, fn entry ->
      level = aqi_to_ui_index(entry.value)

      height_px =
        entry.value
        |> min(max_value)
        |> max(0)
        |> Kernel./(max_value)
        |> Kernel.*(60)
        |> max(3.0)
        |> Float.round(1)

      %{
        height_px: height_px,
        color_class: aqi_to_bar_color(level),
        tooltip: "#{format_local_time(entry.time)} · AQI #{entry.value}"
      }
    end)
  end

  attr :aqi, :integer, required: true
  attr :raw_aqi, :integer, required: true
  attr :pm2_5, :float, required: true
  attr :history, :list, default: []

  def aqi_section_hourly(assigns) do
    hourly = build_hourly_aqi_bars(assigns.history)

    assigns =
      assigns
      |> assign(:hourly, hourly)

    ~H"""
    <div class={
        "flex flex-col items-center justify-center relative p-4 pb-0 gap-2 flex-1 min-h-0 " <>
          aqi_to_text_color(@aqi)
      }>
      <div class={"absolute inset-0 opacity-10 " <> aqi_to_bg_color(@aqi)}></div>
      <div class="absolute top-2 inset-x-0 text-[11px] font-semibold uppercase tracking-[0.6px] text-base-content/60 text-center">
        Air Quality
      </div>

      <div class="transition-transform duration-500 group-hover:scale-110">
        <.icon
          name={aqi_to_icon(@aqi)}
          class="w-20 h-20"
        />
      </div>

      <div class="text-center z-10">
        <h3 class="text-2xl font-black tracking-tight">
          {aqi_to_label(@aqi)}
        </h3>

        <p class="text-xs font-medium text-base-content/60 uppercase tracking-widest mt-1">
          AQI {@raw_aqi}
        </p>
      </div>
    </div>

    <div class="h-[100px] min-h-0 px-2 pb-2 pt-1 flex flex-col gap-1">
      <div class="flex items-center justify-between text-[10px] text-base-content/60 uppercase tracking-[0.4px]">
        <span>Last 24h</span>
      </div>

      <div class="h-full w-full max-w-[198px] mx-auto flex justify-center">
        <div class="relative h-full">
          <div class="h-full flex items-end gap-[2px]">
            <%= for {bar, idx} <- Enum.with_index(@hourly) do %>
              <.tooltip
                text={bar.tooltip}
                position="tooltip-top"
                class="relative z-50 flex items-end flex-none w-[6px]"
                id={"aqi-hour-bar-#{idx}"}
                role="button"
              >
                <div
                  class={[
                    "w-full rounded-[2px] bg-current transition-all duration-500 ease-out",
                    bar.color_class
                  ]}
                  style={"height: #{bar.height_px}px; opacity: 0.9"}
                >
                </div>
              </.tooltip>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp alert_text_color(nil), do: "text-emerald-400"
  defp alert_text_color(%{severity: :mild}), do: "text-amber-400"
  defp alert_text_color(%{severity: :strong}), do: "text-orange-400"
  defp alert_text_color(%{severity: :danger}), do: "text-rose-400"
  defp alert_text_color(_), do: "text-stone-400"

  defp alert_bg_color(nil), do: "bg-emerald-400/40"
  defp alert_bg_color(%{severity: :mild}), do: "bg-amber-400/40"
  defp alert_bg_color(%{severity: :strong}), do: "bg-orange-400/40"
  defp alert_bg_color(%{severity: :danger}), do: "bg-rose-400/40"
  defp alert_bg_color(_), do: "bg-stone-400/40"

  defp alert_icon(nil), do: %{type: :icon, value: "hero-check-circle"}

  defp alert_icon(%{code: :drizzle}),
    do: %{type: :image, value: "/images/weather/light-drizzle.png"}

  defp alert_icon(%{code: :breezy}), do: %{type: :image, value: "/images/weather/wind.png"}
  defp alert_icon(%{code: :sticky}), do: %{type: :image, value: "/images/weather/wet.png"}

  defp alert_icon(%{code: :frost}),
    do: %{type: :image, value: "/images/weather/freezing-drizzle.png"}

  defp alert_icon(%{code: :heavy_rain}),
    do: %{type: :image, value: "/images/weather/heavy-rain.png"}

  defp alert_icon(%{code: :thunderstorm}),
    do: %{type: :image, value: "/images/weather/thundery-outbreaks.png"}

  defp alert_icon(%{code: :strong_wind}), do: %{type: :image, value: "/images/weather/wind.png"}
  defp alert_icon(%{code: :strong_heat}), do: %{type: :image, value: "/images/weather/sunny.png"}

  defp alert_icon(%{code: :strong_cold}),
    do: %{type: :image, value: "/images/weather/light-snow.png"}

  defp alert_icon(%{code: :fog}), do: %{type: :image, value: "/images/weather/fog.png"}

  defp alert_icon(%{code: :severe_ice}),
    do: %{type: :image, value: "/images/weather/ice-pellets.png"}

  defp alert_icon(%{code: :severe_wind}), do: %{type: :image, value: "/images/weather/wind.png"}
  defp alert_icon(%{code: :extreme_heat}), do: %{type: :image, value: "/images/weather/sunny.png"}

  defp alert_icon(%{code: :extreme_cold}),
    do: %{type: :image, value: "/images/weather/blizzard.png"}

  defp alert_icon(%{code: :flood_risk}),
    do: %{type: :image, value: "/images/weather/torrential-rain-shower.png"}

  defp alert_icon(%{code: :thunderstorm_wind}),
    do: %{type: :image, value: "/images/weather/thundery-outbreaks.png"}

  defp alert_icon(_), do: %{type: :icon, value: "hero-exclamation-triangle"}

  defp alert_headline(nil), do: "All clear"
  defp alert_headline(%{text: text}), do: text

  defp alert_time_range(nil), do: "Next 24h"

  defp alert_time_range(%{starts_at: starts_at, ends_at: ends_at}) do
    "#{format_local_time(starts_at)} - #{format_local_time(ends_at)}"
  end

  attr :alerts, :list, default: []

  def alerts_section(assigns) do
    alert = List.first(assigns.alerts)
    icon = alert_icon(alert)

    assigns =
      assigns
      |> assign(:alert, alert)
      |> assign(:icon, icon)

    ~H"""
    <div
      id="weather-alerts"
      class={
        "flex flex-col items-center justify-center relative p-4 pb-0 gap-2 flex-1 min-h-0 " <>
          alert_text_color(@alert)
      }
    >
      <div class={"absolute inset-0 opacity-10 " <> alert_bg_color(@alert)}></div>
      <div class="absolute top-2 inset-x-0 text-[11px] font-semibold uppercase tracking-[0.6px] text-base-content/60 text-center">
        Weather Alert
      </div>

      <div class="transition-transform duration-500 group-hover:scale-110">
        <%= if @icon.type == :image do %>
          <img src={@icon.value} alt="" class="w-20 h-20 object-contain drop-shadow-sm" />
        <% else %>
          <.icon name={@icon.value} class="w-20 h-20" />
        <% end %>
      </div>
    </div>

    <div class="h-[100px] min-h-0 px-4 pb-3 pt-1 flex flex-col items-center justify-center gap-2 text-center">
      <div class="text-[15px] font-semibold text-base-content/80">{alert_headline(@alert)}</div>
      <div class="text-[11px] text-base-content/60 uppercase tracking-[0.4px]">
        {alert_time_range(@alert)}
      </div>
    </div>
    """
  end

  attr :hours, :list, required: true
  attr :sunrise, :any, required: true
  attr :sunset, :any, required: true
  attr :class, :string, default: ""

  def hour_forecast(assigns) do
    entries =
      assigns.hours
      |> List.wrap()
      |> build_hour_timeline(assigns.sunrise, assigns.sunset)

    assigns =
      assigns
      |> assign(:entries, entries)

    ~H"""
    <div id="hour-forecast" class={["p-2 flex flex-col h-full min-h-0", @class]}>
      <div class="flex flex-1 gap-3 items-stretch w-full">
        <%= for entry <- @entries do %>
          <%= if entry.kind in [:sunrise, :sunset] do %>
            <.hour_forecast_sun entry={entry} />
          <% else %>
            <.hour_forecast_hour entry={entry} />
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  attr :entry, :map, required: true

  def hour_forecast_sun(assigns) do
    ~H"""
    <.tooltip
      text={@entry.condition_text}
      position="tooltip-top"
      wrapper_class="flex flex-1 basis-0 min-w-0 h-full"
      class="relative z-40 px-1 py-1"
    >
      <div class="grid h-full min-h-0 w-full justify-items-center grid-rows-[auto_1fr_auto]">
        <div class="text-[12px] leading-none text-base-content/60 font-semibold tracking-wide tabular-nums">
          {Calendar.strftime(@entry.time, "%H:%M")}
        </div>

        <div class="flex items-center justify-center w-full min-h-0">
          <img
            src={@entry.icon}
            alt={@entry.condition_text}
            class="w-11 h-11 object-contain drop-shadow-sm"
          />
        </div>

        <div class="text-[13px] text-base-content/60 tabular-nums leading-none">
          {@entry.label}
        </div>
      </div>
    </.tooltip>
    """
  end

  attr :entry, :map, required: true
  attr :precip_max_mm, :float, default: 15.0
  attr :precip_scaling_factor, :float, default: 4.0

  def hour_forecast_hour(assigns) do
    bar_height =
      precip_bar_height(
        assigns.entry.precip_mm,
        assigns.precip_max_mm,
        assigns.precip_scaling_factor
      )

    assigns = assign(assigns, :bar_height, bar_height)

    ~H"""
    <.tooltip
      text={@entry.condition_text}
      position="tooltip-top"
      wrapper_class="flex flex-1 basis-0 min-w-0 h-full"
      class="relative z-40 px-1 py-1"
    >
      <div class="grid h-full min-h-0 w-full justify-items-center grid-rows-[auto_1fr_auto]">
        <div class="text-[12px] leading-none text-base-content/60 font-semibold tracking-wide tabular-nums">
          {Calendar.strftime(@entry.time, "%H:%M")}
        </div>

        <div class="grid h-full w-full place-items-center">
          <img
            src={@entry.icon}
            alt={@entry.condition_text}
            class="w-11 h-11 object-contain drop-shadow-sm"
          />
        </div>

        <div class="flex flex-col items-center gap-1 leading-none">
          <div class="text-[16px] font-semibold text-base-content/80 tabular-nums">
            {@entry.temp_c}°
          </div>

          <div class="h-10 w-3 rounded-full bg-base-100 border border-base-300/70 relative overflow-hidden">
            <div
              class="absolute bottom-0 inset-x-0 bg-sky-400/80 rounded-full"
              style={"height: #{@bar_height}%"}
            />
          </div>

          <div class="text-[12px] text-base-content/60 tabular-nums">
            {@entry.precip_mm}mm
          </div>
        </div>
      </div>
    </.tooltip>
    """
  end

  defp build_hour_timeline(hours, sunrise, sunset) do
    hour_entries = Enum.map(hours, &with_kind(&1, :hour))

    sun_entries =
      []
      |> maybe_add_sun_entry(sunrise, :sunrise, "Sunrise", "/images/weather/sun-rise.png")
      |> maybe_add_sun_entry(sunset, :sunset, "Sunset", "/images/weather/sun-set.png")

    (hour_entries ++ sun_entries)
    |> Enum.sort_by(&time_sort_key(&1.time))
  end

  defp with_kind(entry, kind) when is_map(entry), do: Map.put(entry, :kind, kind)

  defp maybe_add_sun_entry(entries, %Time{} = time, kind, label, icon) do
    entries ++
      [
        %{
          time: time,
          kind: kind,
          label: label,
          condition_text: label,
          icon: icon
        }
      ]
  end

  defp maybe_add_sun_entry(entries, _time, _kind, _label, _icon), do: entries

  defp precip_bar_height(precip_mm, precip_max_mm, precip_scaling_factor)
       when is_number(precip_mm) and is_number(precip_max_mm) and is_number(precip_scaling_factor) do
    value = precip_mm |> min(precip_max_mm) |> max(0.0)

    if precip_max_mm <= 0.0 do
      0.0
    else
      denom = :math.log(1.0 + precip_scaling_factor * precip_max_mm)

      height =
        if denom <= 0.0 do
          value / precip_max_mm * 100.0
        else
          :math.log(1.0 + precip_scaling_factor * value) / denom * 100.0
        end

      height |> max(0.0) |> Float.round(1)
    end
  end

  defp precip_bar_height(_precip_mm, _precip_max_mm, _precip_scaling_factor), do: 0.0
end

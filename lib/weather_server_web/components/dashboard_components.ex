defmodule WeatherServerWeb.DashboardComponents do
  use Phoenix.Component
  import WeatherServerWeb.CoreComponents
  import WeatherServer.Utils.Weather
  alias WeatherServer.Utils

  @precip_max_mm 15.0
  @precip_scaling_factor 4.0

  attr :title, :string, required: true

  attr :value_id, :string, default: nil

  attr :class, :string, default: ""

  slot :inner_block, required: true

  def stat_card(assigns) do
    ~H"""
    <div class={[
      "
        card
        bg-gradient-to-b from-base-100 to-base-100/85
        border border-base-300/80
        shadow-md hover:shadow-xl
        transition-all duration-200

        h-full relative overflow-hidden
        rounded-xl backdrop-blur-sm

        hover:-translate-y-[1px]
      ",
      @class
    ]}>
      <div class="card-body items-center p-3 gap-1">
        <div class="stat-title text-[11px] uppercase tracking-[0.8px] mb-1 text-base-content/70">
          {@title}
        </div>
        <div
          id={@value_id}
          class="stat-value text-[22px] font-bold text-base-content drop-shadow-sm"
        >
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

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
    <section class="
    card bg-base-200/90 border border-base-300/70
    shadow-xl rounded-2xl backdrop-blur
    min-h-0 relative
    glossy-top-border
    overflow-hidden">
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
    </section>
    """
  end

  attr :aqi, :integer, required: true
  attr :raw_aqi, :integer, required: true
  attr :pm2_5, :float, required: true
  attr :history, :list, default: []

  def aqi_section_hourly(assigns) do
    ~H"""
    <section class="
    card bg-base-200/90 border border-base-300/70
    shadow-xl rounded-2xl backdrop-blur
    min-h-0 relative h-full z-20
    glossy-top-border
    overflow-visible flex flex-col">
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
              <% hourly_entries =
                @history
                |> Enum.reverse()
                |> Enum.take(24)
                |> Enum.map(fn h ->
                  %{value: h.raw_aqi, time: time_from_datetime(h.period_start)}
                end)

              max_value = Enum.max(Enum.map(hourly_entries, & &1.value) ++ [1]) %>
              <%= for {entry, idx} <- hourly_entries |> Enum.take(24) |> Enum.with_index() do %>
                <% level = aqi_to_ui_index(entry.value)

                height_px =
                  entry.value
                  |> min(max_value)
                  |> max(0)
                  |> Kernel./(max_value)
                  |> Kernel.*(60)
                  |> Float.round(1)
                  |> max(3.0)

                tooltip = "#{format_local_time(entry.time)} · AQI #{entry.value}" %>
                <.tooltip
                  text={tooltip}
                  position="tooltip-top"
                  class="relative z-50 flex items-end flex-none w-[6px]"
                  id={"aqi-hour-bar-#{idx}"}
                  role="button"
                >
                  <div
                    class={[
                      "w-full rounded-[2px] bg-current transition-all duration-500 ease-out",
                      aqi_to_bar_color(level)
                    ]}
                    style={"height: #{height_px}px; opacity: 0.9"}
                  >
                  </div>
                </.tooltip>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  @spec format_local_time(Time.t()) :: String.t()
  defp format_local_time(%Time{} = time) do
    Calendar.strftime(time, "%H:%M")
  rescue
    _ -> "--:--"
  end

  @spec time_from_datetime(DateTime.t()) :: Time.t()
  defp time_from_datetime(%DateTime{} = dt) do
    DateTime.to_time(dt)
  end

  @spec seconds_after_midnight(Time.t()) :: non_neg_integer()
  defp seconds_after_midnight(%Time{hour: hour, minute: minute, second: second}) do
    hour * 3600 + minute * 60 + second
  end

  @spec day_night_positions(Time.t() | nil, Time.t() | nil) :: %{
          sunrise: Time.t(),
          sunset: Time.t(),
          sunrise_pct: float(),
          sunset_pct: float(),
          now_pct: float(),
          is_day: boolean()
        }
  defp day_night_positions(%Time{} = sunrise, %Time{} = sunset) do
    %Time{} = local_now = Utils.Time.local_now_time()

    day_seconds = 86_399.0
    sunrise_sec = seconds_after_midnight(sunrise)
    sunset_sec = seconds_after_midnight(sunset)
    now_sec = seconds_after_midnight(local_now)

    raw_sunrise_pct = sunrise_sec / day_seconds * 100
    raw_sunset_pct = sunset_sec / day_seconds * 100
    raw_now_pct = now_sec / day_seconds * 100

    scale_min = 8.0
    scale_span = 84.0
    sunrise_pct = (scale_min + raw_sunrise_pct * scale_span / 100) |> Float.round(1)
    sunset_pct = (scale_min + raw_sunset_pct * scale_span / 100) |> Float.round(1)
    now_pct = (scale_min + raw_now_pct * scale_span / 100) |> Float.round(1)

    %{
      sunrise: sunrise,
      sunset: sunset,
      sunrise_pct: sunrise_pct,
      sunset_pct: sunset_pct,
      now_pct: now_pct,
      is_day: now_sec >= sunrise_sec and now_sec <= sunset_sec
    }
  end

  defp day_night_positions(_, _) do
    now = Utils.Time.local_now_time()
    day_night_positions(now, now)
  end

  attr :sunrise, :any, required: true
  attr :sunset, :any, required: true

  def day_night_cycle(assigns) do
    ~H"""
    <section class="
    card bg-base-200/90 border border-base-300/70
    shadow-xl rounded-2xl backdrop-blur
    min-h-0 relative h-full z-10
    glossy-top-border
    overflow-hidden flex flex-col">
      <%!-- <div class="px-4 pt-3 pb-2 text-[11px] font-semibold uppercase tracking-[0.6px] text-base-content/60"> --%>
      <%!--   Day / Night --%>
      <%!-- </div> --%>
      <div class="absolute top-2 inset-x-0 text-[11px] font-semibold uppercase tracking-[0.6px] text-base-content/60 text-center">
        Day / Night
      </div>

      <div class="flex-1 min-h-0 px-4 pb-4 pt-10 flex items-stretch">
        <% positions = day_night_positions(@sunrise, @sunset)
        local_sunrise = positions.sunrise
        local_sunset = positions.sunset
        sunrise_pct = positions.sunrise_pct
        sunset_pct = positions.sunset_pct
        now_pct = positions.now_pct
        is_day = positions.is_day
        day_span = max(sunset_pct - sunrise_pct, 0.0)
        bottom_span = max(100.0 - sunset_pct, 0.0) %>
        <div class="relative h-full w-2 self-center flex-1 rounded-2xl overflow-hidden">
          <div class="absolute inset-0 opacity-20">
            <div
              class="absolute inset-x-0 top-0 bg-sky-800"
              style={"height: #{sunrise_pct}%"}
            >
            </div>
            <div
              class="absolute inset-x-0 bg-amber-300"
              style={"top: #{sunrise_pct}%; height: #{day_span}%"}
            >
            </div>
            <div
              class="absolute inset-x-0 bg-sky-800"
              style={"top: #{sunset_pct}%; height: #{bottom_span}%"}
            >
            </div>
          </div>

          <div
            class="absolute left-1/2 -translate-x-1/2 -translate-y-1/2"
            style={"top: #{now_pct}%"}
            id="day-night-now"
          >
            <div class="relative w-12 h-16 flex items-start justify-center">
              <div class="w-12 h-12 rounded-full bg-base-200/80 ring-1 ring-base-300/60 shadow-md flex items-center justify-center">
                <.icon
                  name={if(is_day, do: "hero-sun", else: "hero-moon")}
                  class={[
                    "w-7 h-7",
                    if(is_day,
                      do: "text-amber-300",
                      else: "text-slate-300"
                    )
                  ]}
                />
              </div>
              <div class="absolute bottom-0 left-1/2 -translate-x-1/2 w-0 h-0 border-l-[10px] border-r-[10px] border-t-[12px] border-l-transparent border-r-transparent border-t-base-300/60">
              </div>
              <div class="absolute bottom-[1px] left-1/2 -translate-x-1/2 w-0 h-0 border-l-[9px] border-r-[9px] border-t-[11px] border-l-transparent border-r-transparent border-t-base-200/80 drop-shadow-[0_1px_2px_rgba(0,0,0,0.25)]">
              </div>
            </div>
          </div>
        </div>

        <div class="flex-1 h-full relative">
          <div
            class="absolute right-0 -translate-y-1/2 text-2xl font-semibold text-base-content/70 tabular-nums w-[4.5ch] text-right"
            style={"top: #{sunrise_pct}%"}
            id="sunrise-label"
          >
            {Calendar.strftime(local_sunrise, "%H:%M")}
          </div>
          <div
            class="absolute right-0 -translate-y-1/2 text-2xl font-semibold text-base-content/70 tabular-nums w-[4.5ch] text-right"
            style={"top: #{sunset_pct}%"}
            id="sunset-label"
          >
            {Calendar.strftime(local_sunset, "%H:%M")}
          </div>
        </div>
      </div>
    </section>
    """
  end

  attr :hours, :list, required: true
  attr :sunrise, :any, required: true
  attr :sunset, :any, required: true
  attr :class, :string, default: ""

  def hour_forecast(assigns) do
    assigns =
      assigns
      |> assign(
        :precip_max_mm,
        @precip_max_mm
      )
      |> assign(
        :precip_scaling_factor,
        @precip_scaling_factor
      )

    ~H"""
    <section
      id="hour-forecast"
      class={[
        "
        card bg-base-200/90 border border-base-300/70
        shadow-xl rounded-2xl backdrop-blur
        p-2 min-h-0 overflow-visible h-full
        flex flex-col relative z-30
        glossy-top-border
        ",
        @class
      ]}
    >
      <% hours = @hours || []
      entries = build_hour_timeline(hours, @sunrise, @sunset) %>

      <div class="flex gap-3 h-full items-stretch w-full">
        <.tooltip
          :for={entry <- entries}
          text={entry.condition_text}
          position="tooltip-top"
          wrapper_class="flex flex-1 basis-0 min-w-0 h-full"
          class="
          relative z-40 px-1 py-1
          "
        >
          <div class="grid h-full w-full grid-rows-[auto_1fr_auto] justify-items-center">
            <div class="text-[11px] leading-none text-base-content/60 font-semibold tracking-wide tabular-nums">
              {Calendar.strftime(entry.time, "%H:%M")}
            </div>

            <div class="flex items-center justify-center w-full">
              <img
                src={entry.icon}
                alt={entry.condition_text}
                class="w-9 h-9 object-contain drop-shadow-sm"
              />
            </div>

            <div class="flex flex-col items-center gap-0.5 leading-none">
              <%= if entry.kind in [:sunrise, :sunset] do %>
                <div class="text-base opacity-0" aria-hidden="true">0°</div>
                <div class="h-10 w-3 opacity-0" aria-hidden="true"></div>
                <div class="text-[10px] font-semibold text-base-content/60 tabular-nums">
                  {entry.label}
                </div>
              <% else %>
                <div class="text-base font-semibold text-base-content/80 tabular-nums">
                  {entry.temp_c}°
                </div>
                <% bar_height =
                  entry.precip_mm
                  |> min(@precip_max_mm)
                  |> then(fn value ->
                    :math.log(1.0 + @precip_scaling_factor * value) /
                      :math.log(1.0 + @precip_scaling_factor * @precip_max_mm) * 100.0
                  end)
                  |> max(0.0)
                  |> Float.round(1) %>
                <div class="h-10 w-3 rounded-full bg-base-100/60 border border-base-300/70 relative overflow-hidden">
                  <div
                    class="absolute bottom-0 inset-x-0 bg-sky-400/80 rounded-full"
                    style={"height: #{bar_height}%"}
                  >
                  </div>
                </div>

                <div class="text-[10px] text-base-content/60 tabular-nums">
                  {entry.precip_mm}mm
                </div>
              <% end %>
            </div>
          </div>
        </.tooltip>
      </div>
    </section>
    """
  end

  defp build_hour_timeline(hours, sunrise, sunset) do
    hour_entries =
      Enum.map(hours, fn hour ->
        Map.put(hour, :kind, :hour)
      end)

    sun_entries =
      []
      |> maybe_add_sun_entry(sunrise, :sunrise, "Sunrise", "/images/weather/sun-rise.png")
      |> maybe_add_sun_entry(sunset, :sunset, "Sunset", "/images/weather/sun-set.png")

    (hour_entries ++ sun_entries)
    |> Enum.sort_by(&time_sort_key(&1.time))
  end

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

  defp time_sort_key(%Time{} = time), do: {time.hour, time.minute, time.second}
end

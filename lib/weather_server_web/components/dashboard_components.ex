defmodule WeatherServerWeb.DashboardComponents do
  use Phoenix.Component
  import WeatherServerWeb.CoreComponents
  import WeatherServer.Utils.Weather

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
    min-h-0 relative h-full
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
                  %{value: h.raw_aqi, time: format_local_time(h.period_start)}
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

                tooltip = "#{entry.time} · AQI #{entry.value}" %>
                <div
                  class="flex items-end flex-none w-[6px] tooltip tooltip-top"
                  id={"aqi-hour-bar-#{idx}"}
                  data-tip={tooltip}
                  tabindex="0"
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
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp format_local_time(%DateTime{} = dt) do
    tz = Application.get_env(:weather_server, :timezone, "Etc/UTC")

    case DateTime.shift_zone(dt, tz) do
      {:ok, local} ->
        Calendar.strftime(local, "%H:%M")

      {:error, _} ->
        dt
        |> DateTime.add(timezone_fallback_offset_seconds(), :second)
        |> Calendar.strftime("%H:%M")
    end
  rescue
    _ -> "--:--"
  end

  defp timezone_fallback_offset_seconds do
    Application.get_env(:weather_server, :timezone_fallback_offset_seconds, 0)
  end
end

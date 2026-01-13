defmodule WeatherServer.WeatherAlerts do
  alias WeatherServer.Utils.Time, as: TimeUtils

  @type severity :: :mild | :strong | :danger
  @type category :: :precipitation | :temperature | :wind | :other

  defmodule Alert do
    @enforce_keys [:id, :code, :severity, :text, :starts_at, :ends_at]
    defstruct [:id, :code, :severity, :text, :starts_at, :ends_at]

    @type t :: %__MODULE__{
            id: String.t(),
            code: atom(),
            severity: WeatherServer.WeatherAlerts.severity(),
            text: String.t(),
            starts_at: Time.t(),
            ends_at: Time.t()
          }
  end

  @wind_thresholds %{breezy: 20, strong: 35, severe: 55, stormy: 45}
  @rain_thresholds %{
    light_min: 0.1,
    light_max: 0.8,
    heavy: 2.5,
    flood: 8.0,
    flood_heavy: 5.0,
    flood_chance: 80
  }
  @temp_thresholds %{
    mild_heat: 28,
    strong_heat: 33,
    extreme_heat: 39,
    mild_cold: 2,
    strong_cold: -5,
    extreme_cold: -12
  }
  @humidity_thresholds %{sticky: 70, sticky_temp: 24}
  @ice_thresholds %{range_low: -2, range_high: 1, mild_precip: 0.2, severe_precip: 0.5}

  @rules [
    %{code: :drizzle, severity: :mild, category: :precipitation, text: "Light rain or drizzle"},
    %{code: :breezy, severity: :mild, category: :wind, text: "Breezy winds"},
    %{code: :sticky, severity: :mild, category: :temperature, text: "Damp and sticky"},
    %{code: :frost, severity: :mild, category: :temperature, text: "Frost or icy spots"},
    %{code: :heavy_rain, severity: :strong, category: :precipitation, text: "Heavy soaking rain"},
    %{
      code: :thunderstorm,
      severity: :strong,
      category: :precipitation,
      text: "Thunderstorms nearby"
    },
    %{code: :strong_wind, severity: :strong, category: :wind, text: "Strong wind"},
    %{code: :strong_heat, severity: :strong, category: :temperature, text: "Strong heat"},
    %{code: :strong_cold, severity: :strong, category: :temperature, text: "Strong cold"},
    %{code: :fog, severity: :strong, category: :other, text: "Foggy conditions"},
    %{code: :severe_ice, severity: :strong, category: :other, text: "Severe ice on the ground"},
    %{code: :severe_wind, severity: :danger, category: :wind, text: "Severe wind"},
    %{code: :extreme_heat, severity: :danger, category: :temperature, text: "Extreme heat"},
    %{code: :extreme_cold, severity: :danger, category: :temperature, text: "Extreme cold"},
    %{
      code: :flood_risk,
      severity: :danger,
      category: :precipitation,
      text: "Flood risk from rain"
    },
    %{
      code: :thunderstorm_wind,
      severity: :danger,
      category: :precipitation,
      text: "Thunderstorm with strong wind"
    }
  ]

  @category_by_code Map.new(@rules, fn rule -> {rule.code, rule.category} end)

  @spec build_alerts([map()]) :: [Alert.t()]
  def build_alerts(hours) when is_list(hours) do
    hours
    |> future_hours()
    |> Enum.sort_by(&TimeUtils.time_sort_key(&1.time))
    |> build_rule_alerts()
    |> select_top_alert()
  end

  defp future_hours(hours) do
    case TimeUtils.local_now_time() do
      %Time{} = now ->
        Enum.filter(hours, fn hour ->
          Time.compare(hour.time, now) != :lt
        end)

      _ ->
        hours
    end
  end

  defp build_rule_alerts(hours) do
    Enum.flat_map(@rules, fn rule ->
      hours
      |> Enum.filter(&match_rule?(&1, rule.code))
      |> build_time_windows()
      |> Enum.map(&build_alert(rule, &1))
    end)
  end

  defp build_time_windows([]), do: []

  defp build_time_windows([first | rest]) do
    rest
    |> Enum.reduce([%{start: first.time, finish: first.time}], fn hour, [current | acc] ->
      if consecutive?(current.finish, hour.time) do
        [%{current | finish: hour.time} | acc]
      else
        [%{start: hour.time, finish: hour.time} | [current | acc]]
      end
    end)
    |> Enum.reverse()
  end

  defp consecutive?(%Time{} = previous, %Time{} = current) do
    Time.add(previous, 3600, :second) == current
  end

  defp build_alert(rule, %{start: start_time, finish: finish_time}) do
    end_time = Time.add(finish_time, 3600, :second)

    %Alert{
      id: "#{rule.code}-#{Time.to_iso8601(start_time)}",
      code: rule.code,
      severity: rule.severity,
      text: rule.text,
      starts_at: start_time,
      ends_at: end_time
    }
  end

  defp select_top_alert([]), do: []

  defp select_top_alert(alerts) do
    alert =
      Enum.max_by(alerts, fn alert ->
        {
          severity_rank(alert.severity),
          category_rank(alert.code),
          -time_to_seconds(alert.starts_at)
        }
      end)

    [alert]
  end

  defp severity_rank(:mild), do: 1
  defp severity_rank(:strong), do: 2
  defp severity_rank(:danger), do: 3

  defp category_rank(code) do
    case Map.get(@category_by_code, code, :other) do
      :precipitation -> 4
      :temperature -> 3
      :wind -> 2
      :other -> 1
    end
  end

  defp time_to_seconds(%Time{} = time), do: time.hour * 3600 + time.minute * 60 + time.second

  defp match_rule?(hour, :drizzle) do
    precip = value(hour, :precip_mm)
    text = condition_text(hour)

    (precip >= @rain_thresholds.light_min and precip <= @rain_thresholds.light_max) or
      String.contains?(text, "drizzle") or
      String.contains?(text, "light rain")
  end

  defp match_rule?(hour, :breezy) do
    wind = value(hour, :wind_kph)
    wind >= @wind_thresholds.breezy and wind < @wind_thresholds.strong
  end

  defp match_rule?(hour, :sticky) do
    humidity = value(hour, :humidity)
    feelslike = value(hour, :feelslike_c)

    humidity >= @humidity_thresholds.sticky and feelslike >= @humidity_thresholds.sticky_temp
  end

  defp match_rule?(hour, :frost) do
    temp_in_range?(value(hour, :feelslike_c)) and
      value(hour, :precip_mm) >= @ice_thresholds.mild_precip
  end

  defp match_rule?(hour, :heavy_rain) do
    precip = value(hour, :precip_mm)
    precip >= @rain_thresholds.heavy
  end

  defp match_rule?(hour, :thunderstorm) do
    condition_text(hour) |> String.contains?("thunder")
  end

  defp match_rule?(hour, :strong_wind) do
    wind = value(hour, :wind_kph)
    wind >= @wind_thresholds.strong and wind < @wind_thresholds.severe
  end

  defp match_rule?(hour, :strong_heat) do
    temp = value(hour, :feelslike_c)
    temp >= @temp_thresholds.strong_heat and temp < @temp_thresholds.extreme_heat
  end

  defp match_rule?(hour, :strong_cold) do
    temp = value(hour, :feelslike_c)
    temp <= @temp_thresholds.strong_cold and temp > @temp_thresholds.extreme_cold
  end

  defp match_rule?(hour, :fog) do
    text = condition_text(hour)
    String.contains?(text, "fog") or String.contains?(text, "mist")
  end

  defp match_rule?(hour, :severe_ice) do
    temp_in_range?(value(hour, :feelslike_c)) and
      value(hour, :precip_mm) >= @ice_thresholds.severe_precip and
      icy_condition?(hour)
  end

  defp match_rule?(hour, :severe_wind), do: value(hour, :wind_kph) >= @wind_thresholds.severe

  defp match_rule?(hour, :extreme_heat),
    do: value(hour, :feelslike_c) >= @temp_thresholds.extreme_heat

  defp match_rule?(hour, :extreme_cold),
    do: value(hour, :feelslike_c) <= @temp_thresholds.extreme_cold

  defp match_rule?(hour, :flood_risk) do
    precip = value(hour, :precip_mm)
    precip_chance = value(hour, :precip_chance)

    precip >= @rain_thresholds.flood or
      (precip >= @rain_thresholds.flood_heavy and precip_chance >= @rain_thresholds.flood_chance)
  end

  defp match_rule?(hour, :thunderstorm_wind) do
    wind = value(hour, :wind_kph)

    condition_text(hour) |> String.contains?("thunder") and wind >= @wind_thresholds.stormy
  end

  defp condition_text(hour) do
    hour
    |> Map.get(:condition_text, "")
    |> String.downcase()
  end

  defp value(hour, key, default \\ 0) do
    hour
    |> Map.get(key, default)
    |> case do
      nil -> default
      value -> value
    end
  end

  defp temp_in_range?(temp) do
    temp >= @ice_thresholds.range_low and temp <= @ice_thresholds.range_high
  end

  defp icy_condition?(hour) do
    text = condition_text(hour)

    String.contains?(text, "freezing") or
      String.contains?(text, "sleet") or
      String.contains?(text, "ice")
  end
end

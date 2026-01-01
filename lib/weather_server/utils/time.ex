defmodule WeatherServer.Utils.Time do
  @callback now() :: DateTime.t()

  @spec now() :: DateTime.t()
  def now(), do: DateTime.utc_now()

  @spec local_now_time :: Time.t()
  def local_now_time() do
    case DateTime.now(get_tz()) do
      {:ok, datetime} -> DateTime.to_time(datetime)
      _ -> {:error, "Invalid date"}
    end
  end

  @spec get_tz() :: String.t()
  def get_tz(), do: Application.get_env(:weather_server, :timezone, "Etc/UTC")

  @spec parse_time_12h!(String.t()) :: Time.t()
  def parse_time_12h!(str) do
    [time, meridiem] = String.split(str, " ")
    [hour, minute] = String.split(time, ":") |> Enum.map(&String.to_integer/1)

    hour =
      case {hour, meridiem} do
        {12, "AM"} -> 0
        {h, "AM"} -> h
        {12, "PM"} -> 12
        {h, "PM"} -> h + 12
      end

    Time.new!(hour, minute, 0)
  end

  @spec format_local_time(Time.t()) :: String.t()
  def format_local_time(%Time{} = time) do
    Calendar.strftime(time, "%H:%M")
  rescue
    _ -> "--:--"
  end

  @spec time_from_datetime(DateTime.t()) :: Time.t()
  def time_from_datetime(%DateTime{} = dt) do
    DateTime.to_time(dt)
  end
end

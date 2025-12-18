defmodule WeatherServer.Utils.Time do
  @callback now() :: DateTime.t()

  @spec now() :: DateTime.t()
  def now(), do: DateTime.utc_now()
end

defmodule WeatherServer.Repo do
  use Ecto.Repo,
    otp_app: :weather_server,
    adapter: Ecto.Adapters.SQLite3
end

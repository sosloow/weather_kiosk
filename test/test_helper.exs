ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(WeatherServer.Repo, :manual)

Mox.defmock(WeatherServer.Mocks.Time, for: WeatherServer.Utils.Time)
Application.put_env(:weather_server, :time_module, WeatherServer.Mocks.Time)

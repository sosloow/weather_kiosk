defmodule WeatherServer.Apis.Waqi do
  import WeatherServer.Utils.Weather

  defmodule AqiData do
    @type t :: %__MODULE__{
            aqi: integer(),
            pm2_5: number() | nil,
            last_updated: DateTime.t() | nil
          }

    defstruct [:aqi, :pm2_5, :last_updated]
  end

  @spec fetch(String.t()) :: {:ok, AqiData.t()} | {:error, String.t()}
  def fetch(city) do
    api_key = get_api_key()
    params = [token: api_key]

    Req.new(base_url: "https://api.waqi.info/feed")
    |> Req.get(url: "/" <> city, params: params)
    |> handle_response()
  end

  defp handle_response({:ok, %{status: 200, body: %{"status" => "ok", "data" => data}}}) do
    aqi_score = data["aqi"]

    pm25_index = get_in(data, ["iaqi", "pm25", "v"]) || 0

    result = %AqiData{
      aqi: aqi_to_ui_index(aqi_score),
      pm2_5: pm25_index
    }

    {:ok, result}
  end

  defp handle_response({:ok, %{status: status}}), do: {:error, "HTTP #{status}"}
  defp handle_response({:error, _}), do: {:error, "Network Error"}

  defp get_api_key, do: System.get_env("WAQI_API_KEY")
end

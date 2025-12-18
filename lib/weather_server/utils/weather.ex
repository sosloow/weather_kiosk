defmodule WeatherServer.Utils.Weather do
  @spec aqi_to_ui_index(non_neg_integer()) :: 1..6
  def aqi_to_ui_index(score) when score <= 50, do: 1
  def aqi_to_ui_index(score) when score <= 100, do: 2
  def aqi_to_ui_index(score) when score <= 150, do: 3
  def aqi_to_ui_index(score) when score <= 200, do: 4
  def aqi_to_ui_index(score) when score <= 300, do: 5
  def aqi_to_ui_index(_), do: 6

  def calculate_aqi(c) do
    cond do
      c <= 12.0 -> linear(50, 0, 12.0, 0, c)
      c <= 35.4 -> linear(100, 51, 35.4, 12.1, c)
      c <= 55.4 -> linear(150, 101, 55.4, 35.5, c)
      c <= 150.4 -> linear(200, 151, 150.4, 55.5, c)
      c <= 250.4 -> linear(300, 201, 250.4, 150.5, c)
      true -> 300
    end
    |> round()
  end

  defp linear(i_h, i_l, c_h, c_l, c), do: (i_h - i_l) / (c_h - c_l) * (c - c_l) + i_l
end

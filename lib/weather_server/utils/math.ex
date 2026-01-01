defmodule WeatherServer.Utils.Math do
  @spec avg_round(list(), (any() -> number())) :: integer()
  def avg_round(items, fun) when is_list(items) and is_function(fun, 1) do
    count = max(length(items), 1)

    items
    |> Enum.map(fun)
    |> Enum.sum()
    |> Kernel./(count)
    |> round()
  end

  @spec sum_round(list(), (any() -> number())) :: float()
  def sum_round(items, fun) when is_list(items) and is_function(fun, 1) do
    items
    |> Enum.map(fun)
    |> Enum.sum()
    |> Float.round(2)
  end
end

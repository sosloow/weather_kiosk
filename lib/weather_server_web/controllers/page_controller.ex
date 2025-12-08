defmodule WeatherServerWeb.PageController do
  use WeatherServerWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/weather")
  end
end

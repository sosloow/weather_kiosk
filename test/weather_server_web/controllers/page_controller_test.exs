defmodule WeatherServerWeb.PageControllerTest do
  use WeatherServerWeb.ConnCase

  test "GET / redirects to /weather", %{conn: conn} do
    conn = get(conn, "/")
    assert redirected_to(conn) == ~p"/weather"
  end
end

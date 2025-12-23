defmodule ArkNovaCoopWeb.PageControllerTest do
  use ArkNovaCoopWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Ark Nova Cooperative"
  end
end

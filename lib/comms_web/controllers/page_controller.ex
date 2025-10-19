defmodule CommsWeb.PageController do
  use CommsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

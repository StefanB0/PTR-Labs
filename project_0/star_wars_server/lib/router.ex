defmodule StarWarsServer.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/movies" do
    send_resp(conn, 200, "get movies")
  end

  get "/movies/:id" do
    send_resp(conn, 200, "get movie id")
  end

  post "/movies" do
    send_resp(conn, 200, "post movie")
  end

  put "/movies/:id" do
    send_resp(conn, 200, "put movie id")
  end

  patch "/movies/:id" do
    send_resp(conn, 200, "patch movie id")
  end

  delete "/movies/:id" do
    send_resp(conn, 200, "delete movie id")
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end

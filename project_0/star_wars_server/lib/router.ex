defmodule StarWarsServer.Router do
  alias StarWarsServer.Database
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/movies" do
    json = Database.get_all() |> Jason.encode!() |> Jason.Formatter.pretty_print()
    send_resp(conn, 200, json)
  end

  get "/movies/:id" do
    id = String.to_integer(id)
    json = Database.get(id) |> Jason.encode!() |> Jason.Formatter.pretty_print()
    send_resp(conn, 200, json)
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

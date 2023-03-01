defmodule StarWarsServer.Router do
  alias StarWarsServer.EtsDatabse, as: Database
  use Plug.Router

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

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
    movie = Database.create(conn.body_params) |> Jason.encode!() |> Jason.Formatter.pretty_print()
    send_resp(conn, 200, movie)
  end

  put "/movies/:id" do
    id = String.to_integer(id)

    movie =
      Database.update(id, conn.body_params) |> Jason.encode!() |> Jason.Formatter.pretty_print()

    send_resp(conn, 200, movie)
  end

  patch "/movies/:id" do
    id = String.to_integer(id)

    movie =
      Database.patch(id, conn.body_params) |> Jason.encode!() |> Jason.Formatter.pretty_print()

    send_resp(conn, 200, movie)
  end

  delete "/movies/:id" do
    id = String.to_integer(id)
    movie = Database.delete(id) |> Jason.encode!() |> Jason.Formatter.pretty_print()
    send_resp(conn, 200, movie)
  end

  match _ do
    send_resp(conn, 404, "not found")
  end
end

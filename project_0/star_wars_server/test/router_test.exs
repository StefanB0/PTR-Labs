defmodule RouterTest do
  use ExUnit.Case
  use Plug.Test

  alias StarWarsServer.Router
  alias StarWarsServer.EtsDatabse, as: Database

  defp delete_all_movies() do
    Database.get_all()
    |> Enum.each(fn movie -> Database.delete(movie.id) end)
  end

  defp create_mock_movie() do
    Database.create(%{
      "title" => "Star Wars : Episode IV - A New Hope",
      "release_year" => 1977,
      "director" => "George Lucas"
    })
  end

  setup do
    delete_all_movies()
    create_mock_movie()
    :ok
  end

  test "GET /movies" do
    conn = conn(:get, "/movies")
    conn = Router.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) != []
  end

  test "GET /movies/:id" do
    conn = conn(:get, "/movies/1")
    conn = Router.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200

    assert Jason.decode!(conn.resp_body) == %{
             "id" => 1,
             "title" => "Star Wars : Episode IV - A New Hope",
             "release_year" => 1977,
             "director" => "George Lucas"
           }
  end

  test "POST /movies" do
    conn =
      conn(:post, "/movies", %{
        "title" => "Star Wars : Episode IV - A New Hope",
        "release_year" => 1977,
        "director" => "George Lucas"
      })

    conn = Router.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200

    assert Jason.decode!(conn.resp_body) |> Map.drop(["id"]) == %{
             "title" => "Star Wars : Episode IV - A New Hope",
             "release_year" => 1977,
             "director" => "George Lucas"
           }
  end

  test "PUT /movies/:id" do
    conn =
      conn(:put, "/movies/1", %{
        "title" => "Star Wars : Episode IV - A New Hope",
        "release_year" => 1900,
        "director" => "George Lucas"
      })

    conn = Router.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200

    assert Jason.decode!(conn.resp_body) == %{
             "id" => 1,
             "title" => "Star Wars : Episode IV - A New Hope",
             "release_year" => 1900,
             "director" => "George Lucas"
           }
  end

  test "PATCH /movies/:id" do
    conn =
      conn(:patch, "/movies/1", %{
        "release_year" => 2002
      })

    conn = Router.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200

    assert Jason.decode!(conn.resp_body) == %{
             "id" => 1,
             "title" => "Star Wars : Episode IV - A New Hope",
             "release_year" => 2002,
             "director" => "George Lucas"
           }
  end

  test "DELETE /movies/:id" do
    conn = conn(:delete, "/movies/1")
    conn = Router.call(conn, [])
    assert conn.state == :sent
    assert conn.status == 200

    assert Jason.decode!(conn.resp_body) == %{
             "id" => 1,
             "title" => "Star Wars : Episode IV - A New Hope",
             "release_year" => 1977,
             "director" => "George Lucas"
           }
  end
end

defmodule StarWarsServerTest do
  use ExUnit.Case

  alias StarWarsServer.Database

  setup do
    Database.get_all() |> Enum.each(fn movie -> Database.delete(movie.id) end)
    :ok
  end

  test "import movies" do
    assert Database.get_all() == []
    Database.import("store/data.json")
    assert Database.get_all() != []
    assert Database.get_all() |> Enum.count() == 11

    assert Database.get(1) == %{
             id: 1,
             title: "Star Wars : Episode IV - A New Hope",
             release_year: 1977,
             director: "George Lucas"
           }
  end

  test "create movie" do
    movie = Database.create(%{
      title: "Star Wars : Episode IV - A New Hope",
      release_year: 1977,
      director: "George Lucas"
    })

    assert Database.get_all() |> Enum.find(fn movie -> movie.title == "Star Wars : Episode IV - A New Hope" end) == movie
  end

  test "update movie" do
    id = Database.create(%{
      title: "Star Wars : Episode IV - A New Hope",
      release_year: 1977,
      director: "George Lucas"
    }).id

    new_movie = %{
      title: "Star Wars : Episode IV - A New Hope",
      release_year: 1900,
      director: "George Lucas"
    }

    Database.update(id, new_movie)

    new_movie = Map.put(new_movie, :id, id)
    assert Database.get(id) == new_movie
  end
  
  test "patch movie" do
    id = Database.create(%{
      title: "Star Wars : Episode IV - A New Hope",
      release_year: 1977,
      director: "George Lucas"
    }).id

    new_movie = %{
      release_year: 2002
    }

    Database.patch(id, new_movie)

    assert Database.get(id) == %{
             id: id,
             title: "Star Wars : Episode IV - A New Hope",
             release_year: 2002,
             director: "George Lucas"
           }
  end

  test "delete movie" do
    id = Database.create(%{
      title: "Star Wars : Episode IV - A New Hope",
      release_year: 1977,
      director: "George Lucas"
    }).id

    Database.delete(id)

    assert Database.get(id) == nil
  end
end

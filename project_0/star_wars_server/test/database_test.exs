defmodule StarWarsServerTest do
  use ExUnit.Case

  alias StarWarsServer.Database

  setup do
    {:ok, _} = Database.start_link
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

end

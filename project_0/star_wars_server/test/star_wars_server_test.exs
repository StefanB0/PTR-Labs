defmodule StarWarsServerTest do
  use ExUnit.Case
  doctest StarWarsServer

  test "greets the world" do
    assert StarWarsServer.hello() == :world
  end
end

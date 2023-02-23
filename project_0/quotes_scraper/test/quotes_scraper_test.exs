defmodule QuotesScraperTest do
  use ExUnit.Case
  doctest QuotesScraper

  test "greets the world" do
    assert QuotesScraper.hello() == :world
  end
end

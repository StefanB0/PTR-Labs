defmodule QuotesScraper do
  @moduledoc """
  Documentation for `QuotesScraper`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> QuotesScraper.hello()
      :world

  """
  def hello do
    :world
  end

  def request_quote do
    HTTPoison.get!("https://quotes.toscrape.com/")
  end

  def request_dump do
    IO.puts("Status code: #{request_quote().status_code}\n
      Headers: #{inspect(request_quote().headers)}\n
      Body: #{request_quote().body}")
  end

  def parse_quotes do
    request_quote().body
    |> Floki.parse_document!()
    |> Floki.find(".quote")
    |> Enum.map(fn e ->
      %{
        author: Floki.find(e, ".author") |> Enum.map(fn tag -> Floki.text(tag) end),
        tags: Floki.find(e, ".tag") |> Enum.map(fn tag -> Floki.text(tag) end),
        text: Floki.find(e, ".text") |> Enum.map(fn tag -> Floki.text(tag) |> remove_quotes() end)
      }
    end)
  end

  def save_to_json do
    json_binary = Jason.encode_to_iodata!(parse_quotes()) |> Jason.Formatter.pretty_print()
    File.write!("quotes.json", json_binary)
  end

  def string_substitute(string) do
    String.replace(string, "“", "\"")
  end

  def remove_quotes(string) do
    string
    |> String.replace("“", "")
    |> String.replace("”", "")
  end
  
end

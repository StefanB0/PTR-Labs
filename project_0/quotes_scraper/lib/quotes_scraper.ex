defmodule QuotesScraper do
  @moduledoc """
  Documentation for `QuotesScraper`.

  The module has 3 simple functions.
  1. request_dump() - prints the status code, headers and body of the request to the console with no formatting.
  2. parse_quotes() - parses the body of the request and returns a list of maps with the author, tags and text.
  3. save_to_json() - saves the result to a json file.

  """

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
    File.write!("tmp/quotes.json", json_binary)
  end


  defp request_quote do
    HTTPoison.get!("https://quotes.toscrape.com/")
  end

  defp remove_quotes(string) do
    string
    |> String.replace("“", "")
    |> String.replace("”", "")
  end

end

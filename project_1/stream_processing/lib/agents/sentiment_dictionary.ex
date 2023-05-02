defmodule SentimentDictionary do
  use Agent

  # Server API

  def start_link(_args \\ []) do
    dictionary =
      HTTPoison.get!("http://localhost:4000/emotion_values").body
      |> String.split(~r{\r\n})
      |> Enum.map(fn line ->
        [word, score] = String.split(line, "\t")
        {word, score |> String.to_integer()}
      end)
      |> Map.new()

    dictionary |> Debugger.d_inspect(:sentiment)

    Debugger.d_print("Sentiment Dictionary started", :start_up)
    Agent.start_link(fn -> dictionary end, name: __MODULE__)
  end

  # Client API

  def get_sentiment_scores do
    Agent.get(__MODULE__, & &1)
  end
end

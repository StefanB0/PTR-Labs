defmodule StreamProcessing.MixProject do
  use Mix.Project

  def project do
    [
      app: :stream_processing,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {StreamProcessing.Application, []},
      env: [
        eventsource_tweet_url_1:  "localhost:4000/tweets/1",
        eventsource_tweet_url_2:  "localhost:4000/tweets/2",
        swear_words_file:         "config/swear-words.json",
        print_delay:              500,
        debug:                    true,
        # starter_printer_nr:       3,
        # min_printer_nr:           3,
        # max_printer_nr:           10,
        # load_step:                10 # Tweets per second
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:eventsource_ex, "~> 1.1.0"},
      {:jason, "~> 1.3"}
    ]
  end
end

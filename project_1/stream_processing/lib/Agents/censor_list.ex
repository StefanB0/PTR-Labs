defmodule CensorList do
  use Agent

  # Server API

  def start_link(_args \\ []) do
    swear_words =
      Application.fetch_env!(:stream_processing, :swear_words_file)
      |> File.read!()
      |> Jason.decode!()

    Agent.start_link(fn -> swear_words end, name: __MODULE__)
  end

  # Client API

  def get_word_list do
    Agent.get(__MODULE__, & &1)
  end
end

defmodule Week3.IOActor do
  use GenServer

  ### GenServer API

  def init(state), do: {:ok, state}

  def handle_call({:mod, message}, _from, state), do: {:reply, modify_message(message), state}

  ### Client API

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def mod(message), do: GenServer.call(__MODULE__, {:mod, message})

  ### Inner logic

  defp modify_message(message) when is_bitstring(message) do
    {head, tail} = String.next_grapheme(message)
    (head |> String.downcase()) <> tail
  end

  defp modify_message(message) when is_number(message) do
    message + 1
  end

  defp modify_message(_message), do: "I don't know how to HANDLE this"
end

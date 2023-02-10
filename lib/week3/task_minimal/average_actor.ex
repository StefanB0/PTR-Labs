defmodule Week3.AverageActor do
  use GenServer

  ### GenServer API

  def init(state), do: {:ok, state}

  def handle_call({:add, value}, _from, state) do
    state = state ++ [value]
    IO.puts("Current average is #{average(state)}}")
    {:reply, average(state), state}
  end

  ### Client API

  def start(state \\ [0]) do
    IO.puts("Current average is #{average(state)}}")
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def add(value), do: GenServer.call(__MODULE__, {:add, value})

  ### Logic

  defp average(list), do: Enum.sum(list) / length(list)
end

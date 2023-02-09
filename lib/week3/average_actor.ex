defmodule Week3.AverageActor do
  use GenServer

  ### GenServer API

  def init(state), do: {:ok, state}

  def handle_call({:add, value}, _from, state), do: {:reply, (Enum.sum(state) + value) / length(state) + 1, state ++ [value]}

  ### Client API

  def start(state \\ [0]) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def add(value), do: GenServer.call(__MODULE__, {:add, value})
end

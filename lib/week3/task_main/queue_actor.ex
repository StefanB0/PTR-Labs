defmodule QueueActor do
  use GenServer

  ### GenServer API

  def init(state), do: {:ok, state}

  def handle_call(:pop, _from, []), do: {:reply, nil, []}

  def handle_call(:pop, _from, [value | state]) do
    {:reply, value, state}
  end

  def handle_call(:status, _from, state), do: {:reply, state, state}

  def handle_call({:push, value}, _from, state) when not is_list(value) do
    {:reply, :ok, state ++ [value]}
  end

  def handle_call({:push, value}, _from, state), do: {:reply, :ok, state ++ value}

  ### Client API / Helper functions

  def start(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def push(value), do: GenServer.call(__MODULE__, {:push, value})
  def pop, do: GenServer.call(__MODULE__, :pop)
  def status, do: GenServer.call(__MODULE__, :status)
end

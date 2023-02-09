defmodule Week3.MinimalActor do
  use GenServer

  @moduledoc """
  A simple agent that can do simple things, like print messages\
  ```
  """

  @doc """
  Helper function to start the agent
  """
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @doc """
  Genserver.init/1 callback
  """
  def init(state), do: {:ok, state}

  def handle_call({:echo, message}, _from, state) do
    IO.puts(message)
    {:reply, :ok, state}
  end

  def echo(message), do: GenServer.call(__MODULE__, {:echo, message})
end

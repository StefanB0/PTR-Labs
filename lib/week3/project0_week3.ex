defmodule MinimalAgent do
  use Agent

  @spec start :: {:error, any} | {:ok, pid}
  def start() do
    Agent.start_link(fn -> "" end, name: __MODULE__)
  end

  def echo(message \\ 0) do
    Agent.update(__MODULE__, fn _state -> message end)
    Agent.get(__MODULE__, & &1) |> IO.puts()
  end
end

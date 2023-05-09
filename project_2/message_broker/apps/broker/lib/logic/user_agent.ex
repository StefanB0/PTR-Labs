defmodule Logic.UserAgent do
  use Agent

  def start_link(_args) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_subscriber(socket, id) do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, socket, id)
    end)
  end

  def get_subscriber(socket) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, socket)
    end)
  end

  def delete_subscriber(socket) do
    Agent.update(__MODULE__, fn state ->
      Map.delete(state, socket)
    end)
  end
end

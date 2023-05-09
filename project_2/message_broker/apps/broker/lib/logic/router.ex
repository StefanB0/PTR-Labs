defmodule Logic.Router do
  use GenServer

  # Server API

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    {:ok, {}}
  end

  ## Server Logic

  ## Server Callbacks

  def handle_call({:tcp, socket, message}, _from, state) do
    Logic.TcpParser.parse(socket, message)
    {:reply, :ok, state}
  end

  # Client API

  def route(:tcp, socket, message) do
    GenServer.call(__MODULE__, {:tcp, socket, message})
  end

  def route(:mqtt, socket, message) do
    GenServer.call(__MODULE__, {:mqtt, socket, message})
  end
end

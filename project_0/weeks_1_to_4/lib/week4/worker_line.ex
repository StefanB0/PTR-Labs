defmodule Week4.WorkerLine do
  use GenServer

  ### Server API

  def init(_args) do
    # workers = Enum.map(1..4, fn _e -> Week4.WorkerLine.WorkerNode.start |> elem(1) end)

    workers =
      [Worker1, Worker2, Worker3, Worker4]
      |> Enum.map(fn w_name ->
        %{id: w_name, start: {Week4.WorkerLine.WorkerNode, :start, []}}
      end)
      |> Supervisor.start_link(strategy: :one_for_one)
      |> elem(1)
      |> Supervisor.which_children()
      |> Enum.map(fn {_, pid, _, _} -> pid end)

    {:ok, workers}
  end

  def handle_call({:process_message, message}, _from, [w1, w2, w3, w4]) do
    message = GenServer.call(w1, {:split, message})
    message = GenServer.call(w2, {:lowercase, message})
    message = GenServer.call(w3, {:join, message})
    GenServer.call(w4, {:print, message})

    {:reply, :ok, [w1, w2, w3, w4]}
  end

  ### Client API
  def start() do
    child = [
      %{
        id: __MODULE__,
        start: {__MODULE__, :start_link, []}
      }
    ]

    Supervisor.start_link(child, strategy: :one_for_one)
  end

  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def process_message(message), do: GenServer.call(__MODULE__, {:process_message, message})

  def test() do
    GenServer.call(__MODULE__, {:process_message, "Hello"})
    GenServer.call(__MODULE__, {:process_message, "Mucias Gracias"})
    GenServer.call(__MODULE__, {:process_message, "Mainland China"})
  end
end

defmodule Week4.WorkerLine.WorkerNode do
  use GenServer

  ### Server API

  def init(args), do: {:ok, args}

  def handle_call({:split, message}, _from, state) do
    {:reply, String.split(message), state}
  end

  def handle_call({:lowercase, message}, _from, state) do
    message =
      message
      |> Enum.map(&String.downcase(&1))
      |> Enum.map(
        &(String.replace(&1, "m", " ")
          |> String.replace("n", "m")
          |> String.replace(" ", "n"))
      )

    {:reply, message, state}
  end

  def handle_call({:join, message}, _from, state) do
    {:reply, Enum.join(message, " "), state}
  end

  def handle_call({:print, message}, _from, state) do
    IO.puts(message)
    {:reply, :ok, state}
  end

  ### Client API

  def start(), do: GenServer.start_link(__MODULE__, [])

  def split(pid, message), do: GenServer.call(pid, {:split, message})

  def lowercase(pid, message), do: GenServer.call(pid, {:lowercase, message})

  def join(pid, message), do: GenServer.call(pid, {:join, message})

  def print(pid, message), do: GenServer.call(pid, {:print, message})
end

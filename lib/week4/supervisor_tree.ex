defmodule Week4.SupervisorTree.MainSupervisor do
  use GenServer, type: :supervisor

  alias Week4.SupervisorTree.WheelSupervisor
  alias Week4.SupervisorTree.Airbags
  alias Week4.SupervisorTree.Sensor

  # Week4.SupervisorTree.MainSupervisor.start_link()
  # Week4.SupervisorTree.MainSupervisor.crash_children()

  def init(_args) do
    IO.puts("Starting MainSupervisor")

    children = [
      WheelSupervisor,
      Supervisor.child_spec({Sensor, "cabin_sensor"}, id: :cabin_sensor),
      Supervisor.child_spec({Sensor, "motor_sensor"}, id: :motor_sensor),
      Supervisor.child_spec({Sensor, "chasis_sensor"}, id: :chasis_sensor)
    ]

    Airbags.start(self())
    Supervisor.start_link(children, strategy: :one_for_one, max_restarts: 1)
  end

  def handle_call(:get_children, _from, pid_s) do
    # Supervisor.which_children(pid_s) |> IO.inspect(label: "Main supervisor children")
    children = Supervisor.which_children(pid_s) |> Enum.map(fn {_, pid, _, _} -> pid end)
    {:reply, children, pid_s}
  end

  def handle_cast(:crash, _state), do: exit(:crash)

  ### Client API

  def start_link(), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def get_children(), do: GenServer.call(__MODULE__, :get_children)

  def crash(), do: GenServer.cast(__MODULE__, :crash)

  def crash_children() do
    get_children() |> Enum.take(2) |> Enum.each(fn pid -> Process.exit(pid, :kill) end)
  end
end

defmodule Week4.SupervisorTree.WheelSupervisor do
  use GenServer, type: :supervisor

  alias Week4.SupervisorTree.Sensor

  ### Server API

  def init(_args) do
    IO.puts("Starting wheel supervisor")

    children = [
      Supervisor.child_spec({Sensor, "wheel_sensor1"}, id: :wheel_sensor1),
      Supervisor.child_spec({Sensor, "wheel_sensor2"}, id: :wheel_sensor2),
      Supervisor.child_spec({Sensor, "wheel_sensor3"}, id: :wheel_sensor3),
      Supervisor.child_spec({Sensor, "wheel_sensor4"}, id: :wheel_sensor4)
    ]

    Supervisor.start_link(children, strategy: :one_for_one, max_restarts: 2)
  end

  def handle_call(:get_children, _from, pid_s) do
    # Supervisor.which_children(pid_s) |> IO.inspect(label: "Wheel supervisor children")
    children = Supervisor.which_children(pid_s) |> Enum.map(fn {_, pid, _, _} -> pid end)
    {:reply, children, pid_s}
  end

  def handle_cast(:crash, _state), do: exit(:crash)

  ### Client API

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)

  def get_children(), do: GenServer.call(__MODULE__, :get_children)

  def crash(), do: GenServer.cast(__MODULE__, :crash)
end

defmodule Week4.SupervisorTree.Sensor do
  use GenServer

  def init(args) do
    IO.puts("Starting " <> args)
    {:ok, []}
  end

  def handle_cast(:crash, _state), do: exit(:crash)

  def start_link(args), do: GenServer.start_link(__MODULE__, args)

  def crash(pid), do: GenServer.cast(pid, :crash)
end

defmodule Week4.SupervisorTree.Airbags do
  def start(pid) do
    spawn(fn ->
      Process.monitor(pid)
      IO.puts("Airbag deployed")

      receive do
        _ ->
          # IO.inspect(msg, label: "airbags message")
          IO.puts("\n\n--- Deploying Airbags ---\n\n")
      end
    end)
  end
end

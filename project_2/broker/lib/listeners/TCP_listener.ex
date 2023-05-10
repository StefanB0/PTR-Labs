defmodule Listeners.TCPListener do
  use Task, restart: :permanent, shutdown: 5000
  require Logger

  def start_link(_args) do
    Logger.info("Starting TCP Listener")
    port = Application.get_env(:broker, :tcp_port)
    Task.start_link(__MODULE__, :listen, [port])
  end

  def listen(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Listening on port #{port}")
    accept(socket)
  end

  def accept(socket) do
    {:ok, client_socket} = :gen_tcp.accept(socket)
    write_to_client(connection_message(), client_socket)
    Logger.info("Client connected")
    Task.Supervisor.start_child(Listeners.TaskSupervisor, fn -> connection_listen(client_socket) end)
    accept(socket)
  end

  defp write_to_client(message, client_socket), do: :gen_tcp.send(client_socket, message)

  defp connection_listen(client_socket) do
    {response, message} = :gen_tcp.recv(client_socket, 0)
    unless response == :error do
      message |> handle_response(client_socket)
      connection_listen(client_socket)
    else
      :gen_tcp.close(client_socket)
      Logger.info("Client disconnected")
    end
  end

  defp handle_response(message, client_socket) do
    if message |> Logic.TcpParser.parse_string() |> hd == "PUB" do
      write_to_client("PUBACK\n", client_socket)
    end

    Logic.Router.route(:tcp, client_socket, message)
  end

  def connection_message() do
    """
    200 Welcome to the Broker

    Here is a list of commands for consumers:
    CONNUSR: connect as user
    RECONN/{ID}: reconnect as user with id
    SUB/[TOPIC]: subscribe to comma separated topics
    UNSUB/[TOPIC]: unsubscribe from comma separated topic
    PUBACK/{Packet ID}: publish acknowledge message

    Here is a list of commands for publishers:
    PUB/{TOPIC}/{MESSAGE}: publish message to topic. Limited to one topic. Message is bitstring.
    ----------
    """
  end
end

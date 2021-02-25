defmodule Ral.Server do
  require Logger

  @socket_file "#{System.user_home()}/opts/ral.sock"
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(arg) do
    pid = spawn_link(__MODULE__, :accept, arg)
    Process.register(pid, __MODULE__)
    {:ok, pid}
  end

  defp socket_config do
    File.mkdir_p(Path.dirname(@socket_file))
    File.rm(@socket_file)
    {:ifaddr, {:local, @socket_file}}
  end

  def accept() do
    {:ok, socket} =
      :gen_tcp.listen(
        0,
        [:binary, packet: 4, active: false, reuseaddr: true] ++ [socket_config()]
      )

    Logger.warn("Listening on socket file #{@socket_file}...")

    loop_accept(socket)
  end

  def loop_accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Ral.Server.TaskSupervisor, fn -> serve(client) end)
    Logger.warn("Accept a new client #{inspect(client)}.")
    :gen_tcp.controlling_process(client, pid)
    loop_accept(socket)
  end

  defp get_choke(data) do
    case Param.extract(data) do
      [func_name | params] ->
        {allow?, total, rest, next} = apply(Ral.Cell, func_name, params)
        <<2, 0::32, allow?::32, 2, 0::32, total::32, 2, 0::32, rest::32, 3, 0::32, next::float>>

      _ ->
        "error match"
    end
  end

  def serve(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        :gen_tcp.send(socket, get_choke(data))
        serve(socket)

      _ ->
        Logger.warn("Lose connection")
    end
  end
end

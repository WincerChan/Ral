defmodule Ral.Server do
  require Logger

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

  defp socket_config(dir, sock) do
    full_name = Path.join(dir, sock)
    File.mkdir_p(Path.dirname(full_name))
    File.rm(full_name)
    {:ifaddr, {:local, full_name}}
  end

  def accept(host, port) when is_tuple(host) do
    {:ok, socket} =
      :gen_tcp.listen(
        port,
        [:binary, packet: 4, active: false, reuseaddr: true, ip: host]
      )

    Logger.warn("Listening on  #{inspect(host)}:#{port}...")

    loop_accept(socket)
  end

  def accept(path, file) do
    {:ok, socket} =
      :gen_tcp.listen(
        0,
        [:binary, packet: 4, active: false, reuseaddr: true] ++
          [socket_config(path, file)]
      )

    Logger.warn("Listening on socket file #{file}...")

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

        <<2, 0::32, allow?::64, 2, 0::32, total::64, 2, 0::32, rest::64, 3, 0::32, next::float>>

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

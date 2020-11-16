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

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    loop_accept(socket)
  end

  def loop_accept(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.warn("Accept a new client #{inspect(client)}.")

    pid = spawn_link(__MODULE__, :serve, [client])

    :ok = :gen_tcp.controlling_process(client, pid)
    loop_accept(socket)
  end

  def serve(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    :gen_tcp.send(socket, data)
    serve(socket)
  end
end

defmodule Ral.CMD do
  @doc """
  Supervisor required this specification.
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  @doc """
  Register the run/0 function as process take over by supervisor.
  """
  @spec start_link(any) :: {:ok, pid}
  def start_link(_) do
    pid = spawn_link(&run/0)

    Process.register(pid, __MODULE__)
    {:ok, pid}
  end

  @doc """
  Receive other process command
  """
  @spec run :: no_return
  def run do
    receive do
      {:delete, d_score?, score} -> Ral.ETS.delete({d_score?, score})
      {:insert, key, now, rest} -> Ral.ETS.insert({key, now, rest})
      _ -> nil
    end

    run()
  end
end

defmodule Ral.CMD do
  @doc """
  Starting a Ral.CMD process.
  """
  def init() do
    {:ok, nil}
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_) do
    # GenServer.start_link(__MODULE__, nil, name: __MODULE__)
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

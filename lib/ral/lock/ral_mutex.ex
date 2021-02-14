defmodule Mutex do
  use GenServer

  alias :ets, as: ETS
  @lock_signal :ral_locked?
  @empty_queue :queue.new()

  def init(_) do
    ETS.new(@lock_signal, [:set, :named_table, :public])
    {:ok, nil}
  end

  def new(name), do: GenServer.start_link(__MODULE__, nil, name: name)

  def start_link(ops) do
    with {:ok, name} <- Keyword.fetch(ops, :name),
         {:ok, pid} = GenServer.start_link(__MODULE__, nil, name: name) do
      {:ok, pid}
    end
  end

  def handle_call({:acquire, id}, {pid, _ref} = from, _state) do
    # atomic
    case ETS.lookup(@lock_signal, id) do
      [{_id, _n, queue}] ->
        ETS.update_element(@lock_signal, id, [{3, :queue.snoc(queue, from)}])
        {:noreply, nil}

      [] ->
        ETS.insert(@lock_signal, {id, 0, :queue.snoc(@empty_queue, pid)})
        {:reply, :ok, nil}
    end
  end

  def acquire(ref_pid, key) do
    with id <- {ref_pid, key},
         self_queue <- {id, -1, :queue.snoc(@empty_queue, self())} do
      case ETS.update_counter(@lock_signal, id, {2, 1}, self_queue) do
        0 -> :ok
        _ -> GenServer.call(ref_pid, {:acquire, id})
      end
    end

    :ok
  end

  defp reply(:empty), do: nil

  defp reply({:value, from}) do
    GenServer.reply(from, :ok)
  end

  defp do_queue(n, rest) do
    rest
    |> :queue.peek()
    |> reply()

    [{2, max(n - 1, 0)}, {3, rest}]
  end

  def handle_cast({:release, id}, _state) do
    # atomic
    case ETS.lookup(@lock_signal, id) do
      [] ->
        []

      [{_id, n, q}] ->
        case :queue.out(q) do
          {{:value, _}, @empty_queue} ->
            ETS.delete(@lock_signal, id)

          {{:value, _}, rest} ->
            ETS.update_element(@lock_signal, id, do_queue(n, rest))
        end
    end

    {:noreply, nil}
  end

  def release(ref_pid, key) do
    with id <- {ref_pid, key} do
      GenServer.cast(ref_pid, {:release, id})
    end

    :ok
  end

  defmacro atomic(ref_pid, key \\ nil, do: block) do
    quote do
      Mutex.acquire(unquote(ref_pid), unquote(key))
      ret = unquote(block)
      Mutex.release(unquote(ref_pid), unquote(key))
      ret
    end
  end
end

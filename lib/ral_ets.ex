defmodule Ral.ETS do
  use GenServer
  alias :ets, as: ETS
  @score Application.get_env(:ral, :score)
  @member Application.get_env(:ral, :member)

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    ETS.new(@member, [
      :set,
      :protected,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    ETS.new(@score, [
      :ordered_set,
      :protected,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    {:ok, nil}
  end

  def handle_cast({:insert, key, now, rest}, state) do
    ETS.insert(@member, {key, now, rest})
    ETS.insert(@score, {{now, key}})
    {:noreply, state}
  end

  def handle_cast({:delete, d_score?, {prev, key}}, state) do
    if d_score?, do: ETS.delete(@score, {prev, key})
    delete_if_expired?(ETS.first(@score), key)
    {:noreply, state}
  end

  def insert({key, now, rest}) do
    GenServer.cast(__MODULE__, {:insert, key, now, rest})
  end

  def delete({d_score?, {prev, key}}) do
    GenServer.cast(__MODULE__, {:delete, d_score?, {prev, key}})
  end

  @spec delete_if_expired?(:"$end_of_table" | {DateTime.t(), Atom}, Atom) :: nil
  defp delete_if_expired?(:"$end_of_table", _), do: nil

  defp delete_if_expired?({prev, key}, new_key) when key != new_key do
    if DateTime.diff(DateTime.utc_now(), prev) >= 300 do
      ETS.delete(@member, key)

      ETS.delete(@score, {prev, key})
      delete_if_expired?(ETS.first(@score), new_key)
    end
  end

  defp delete_if_expired?({_, _}, _), do: nil
end

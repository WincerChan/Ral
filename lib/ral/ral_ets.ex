defmodule Ral.ETS do
  use GenServer
  alias :ets, as: ETS
  @score Application.get_env(:ral, :score)
  @member Application.get_env(:ral, :member)

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    ETS.new(@score, [
      :ordered_set,
      :protected,
      :named_table,
      {:write_concurrency, true},
    ])
    ETS.new(@member, [
      :set,
      :public,
      :named_table,
      {:read_concurrency, true},
    ])

    {:ok, nil}
  end

  def handle_cast({:upsert, key, prev, now}, state) do
    ETS.delete(@score, {prev, key})
    delete_if_expired?(ETS.first(@score), key)
    ETS.insert(@score, {{now, key}})
    {:noreply, state}
  end

  def upsert(info) do
    GenServer.cast(__MODULE__, info)
  end

  def update(key, total, now, rest) do
    ETS.insert(@member, {key, total, now, rest})
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

  defp delete_if_expired?(_, _), do: nil
end

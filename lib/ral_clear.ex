defmodule Ral.Clear do
  use GenServer

  alias :ets, as: ETS
  @score Application.get_env(:ral, :score)
  @member Application.get_env(:ral, :member)

  @doc """
  Starting a Ral.Clear process.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec init(any) :: {:ok, nil}
  def init(_) do
    ETS.new(@member, [:set, :protected, :named_table])
    ETS.new(@score, [:ordered_set, :protected, :named_table])
    {:ok, nil}
  end

  @spec delete({:delete, boolean(), {DateTime.t(), atom()}}) :: :ok
  def delete(ops) do
    GenServer.cast(__MODULE__, ops)
  end

  @spec insert({:insert, atom(), DateTime.t(), number()}) :: :ok
  def insert(ops) do
    GenServer.cast(__MODULE__, ops)
  end

  def handle_cast({:delete, d_score?, {prev, key}}, state) do
    if d_score?, do: ETS.delete(@score, {prev, key})
    delete_if_expired?(ETS.first(@score), key)
    {:noreply, state}
  end

  def handle_cast({:insert, key, now, rest}, state) do
    ETS.insert(@member, {key, now, rest})
    ETS.insert(@score, {{now, key}})
    {:noreply, state}
  end

  defp time_diff(prev), do: DateTime.diff(DateTime.utc_now(), prev)

  @spec delete_if_expired?(:"$end_of_table" | {DateTime.t(), Atom}, Atom) :: nil
  def delete_if_expired?(:"$end_of_table", _), do: nil

  def delete_if_expired?({prev, key}, new_key) when key != new_key do
    if time_diff(prev) >= 300 do
      ETS.delete(@member, key)

      ETS.delete(@score, {prev, key})
      delete_if_expired?(ETS.first(@score), new_key)
    end
  end

  def delete_if_expired?({_, _}, _), do: nil
end

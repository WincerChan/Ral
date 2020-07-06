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
    pid = spawn_link(&run/0)
    Process.register(pid, :clear)

    {:ok, pid}
  end

  def init(_) do
    {:ok, nil}
  end

  def run do
    receive do
      {:delete, d_score?, score} -> delete({d_score?, score})
      {:insert, key, now, rest} -> insert({key, now, rest})
      _ -> nil
    end

    run()
  end

  # @spec delete({:delete, boolean(), {DateTime.t(), atom()}}) :: :ok
  def delete({d_score?, {prev, key}}) do
    if d_score?, do: ETS.delete(@score, {prev, key})
    delete_if_expired?(ETS.first(@score), key)
  end

  def insert({key, now, rest}) do
    ETS.insert(@member, {key, now, rest})
    ETS.insert(@score, {{now, key}})
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

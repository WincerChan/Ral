defmodule Ral.Clear do
  alias :ets, as: ETS
  @member Application.get_env(:ral, :member)
  @score Application.get_env(:ral, :score)

  @doc """
  Starting a Ral.Clear process.
  """
  @spec start :: pid
  def start do
    spawn(&run/0)
    |> Process.register(:clear)
  end

  @doc """
  Receive other process command
  """
  @spec run :: no_return
  def run do
    receive do
      {:delete, d_score?, score} -> do_delete(d_score?, score)
      {:insert, key, now, rest} -> do_insert({key, now, rest})
      _ -> nil
    end

    run()
  end

  defp do_delete(d_score?, {prev, key}) do
    if d_score?, do: ETS.delete(@score, {prev, key})
    delete_if_expired?(ETS.first(@score), key)
  end

  defp do_insert({key, now, rest}) do
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

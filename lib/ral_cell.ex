defmodule Ral.Cell do
  alias :ets, as: ETS

  @total Application.get_env(:ral, :total)
  @speed Application.get_env(:ral, :speed)
  @member Application.get_env(:ral, :member)

  @spec choke(any) :: {boolean, integer, integer, float}
  def choke(key) do
    lookup(key)
    |> calc_rest()
    |> allow?(key)
  end

  defp lookup(key) do
    case ETS.lookup(@member, key) do
      [{_, prev, rest}] -> {rest, prev, true}
      _ -> {@total, DateTime.utc_now(), false}
    end
  end

  defp calc_rest({rest, prev, d_score?}) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, prev, :millisecond) / 1_000

    {elapsed * @speed + rest - 1, now, d_score?, prev}
  end

  defp get_next_time({rest, now, prev}) do
    amount = 1 / @speed
    elapsed = DateTime.diff(now, prev, :millisecond) / 1_000

    cond do
      elapsed > amount ->
        2 * amount - elapsed

      true ->
        if rest >= 1, do: 0.0, else: amount - elapsed
    end
  end

  defp allow?({rest, now, d_score?, prev}, key) do
    next_avaliable = get_next_time({rest, now, prev}) |> Float.round(2)
    new_rest = min(rest, @total) |> round()

    cond do
      rest < 0 ->
        {false, @total, 0, next_avaliable}

      true ->
        send(Ral.CMD, {:delete, d_score?, {prev, key}})
        send(Ral.CMD, {:insert, key, now, if(rest <= 0, do: 0, else: new_rest)})
        {true, @total, new_rest, next_avaliable}
    end
  end
end

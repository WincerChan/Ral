defmodule Ral.Cell do
  alias :ets, as: ETS

  @member Application.get_env(:ral, :member)

  def choke(key, total, speed) do
    lookup(key, total)
    |> calc_rest(speed)
    |> allow?(key, total)
  end

  defp lookup(key, total) do
    case ETS.lookup(@member, key) do
      [{_, prev, rest}] -> {rest, prev, true}
      _ -> {total, DateTime.utc_now(), false}
    end
  end

  defp calc_rest({rest, prev, d_score?}, speed) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, prev, :millisecond)
    new_rest = elapsed * speed / 1_000 + rest - 1

    next_time =
      cond do
        new_rest >= 1 -> 0.0
        new_rest >= 0 -> (1 - new_rest) / speed
        true -> 10 - (new_rest + 1) / speed
      end
      |> Float.round(2)

    {new_rest, now, d_score?, prev, next_time}
  end

  defp allow?({rest, now, d_score?, prev, next_time}, key, total) do
    new_rest = min(rest, total)

    cond do
      rest < 0 ->
        {false, total, 0, next_time}

      true ->
        send(Ral.CMD, {:delete, d_score?, {prev, key}})
        send(Ral.CMD, {:insert, key, now, if(rest <= 0, do: 0, else: new_rest)})
        {true, total, round(new_rest), next_time}
    end
  end
end

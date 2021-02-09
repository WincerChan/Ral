defmodule Ral.Cell do
  alias :ets, as: ETS
  require Mutex

  @member Application.get_env(:ral, :member)

  def choke(key, total, speed) do
    Mutex.atomic :ral_lock, key do
      lookup(key, total)
      |> calc_rest({total, speed})
      |> allow?({key, total, speed})
    end
  end

  defp lookup(key, total) do
    case ETS.lookup(@member, key) do
      [{_, old_total, prev, rest}] -> {old_total, rest, prev}
      _ -> {total, total, DateTime.utc_now()}
    end
  end

  defp calc_rest({old_total, rest, prev}, {total, speed}) do
    now = DateTime.utc_now()
    elapsed = DateTime.diff(now, prev, :millisecond)
    new_rest = elapsed * speed / 1_000 + rest - 1 - old_total + total

    {new_rest, now, prev}
  end

  defp get_next_time(rest, speed) do
    cond do
      rest >= 1 -> 0.0
      rest >= 0 -> (1 - rest) / speed
      rest < -1 -> 1 / speed
      true -> 10 - (rest + 1) / speed
    end
    |> Float.round(2)
  end

  defp allow?({rest, now, prev}, {key, total, speed}) do
    new_rest = min(rest, total)
    next_time = get_next_time(rest, speed)

    cond do
      new_rest < 0 ->
        {0, total, 0, next_time}

      true ->
        Ral.ETS.upsert({:upsert, key, prev, now})
        Ral.ETS.update(key, total, now, new_rest)
        {1, total, round(new_rest), next_time}
    end
  end
end

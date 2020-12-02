defmodule Ral.Cell do
  alias :ets, as: ETS

  @total Application.get_env(:ral, :total)
  @speed Application.get_env(:ral, :speed)
  @member Application.get_env(:ral, :member)

  def choke(key) when is_atom(key), do: check_choke(key)

  def choke(key) when is_binary(key),
    do: key |> String.trim() |> String.to_atom() |> check_choke()

  defp check_choke(key) do
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
    elapsed = DateTime.diff(now, prev, :millisecond)
    new_rest = elapsed * @speed / 1_000 + rest - 1

    next_time =
      cond do
        new_rest >= 1 -> 0.0
        new_rest >= 0 -> (1 - new_rest) / @speed
        true -> 10 - (new_rest + 1) / @speed
      end
      |> Float.round(2)

    {new_rest, now, d_score?, prev, next_time}
  end

  defp allow?({rest, now, d_score?, prev, next_time}, key) do
    new_rest = min(rest, @total)

    cond do
      rest < 0 ->
        {false, @total, 0, next_time}

      true ->
        send(Ral.CMD, {:delete, d_score?, {prev, key}})
        send(Ral.CMD, {:insert, key, now, if(rest <= 0, do: 0, else: new_rest)})
        {true, @total, round(new_rest), next_time}
    end
  end
end

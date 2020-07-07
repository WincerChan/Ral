defmodule Ral.Cell do
  alias :ets, as: ETS

  @total Application.get_env(:ral, :total)
  @speed Application.get_env(:ral, :speed)
  @member Application.get_env(:ral, :member)

  @spec choke(any) :: boolean
  def choke(key) do
    lookup(key)
    |> calc_rest()
    |> allow?(key)
  end

  defp calc_rest({rest, prev, d_score?}) do
    n = DateTime.utc_now()

    {DateTime.diff(n, prev, :millisecond) * @speed / 1000 + rest - 1, n, d_score?, prev}
  end

  defp lookup(key) do
    case ETS.lookup(@member, key) do
      [{_, prev, rest}] -> {rest, prev, true}
      _ -> {@total, DateTime.utc_now(), false}
    end
  end

  defp allow?({rest, now, d_score?, prev}, key) do
    new_rest = min(rest, @total) |> round()
    send(Ral.CMD, {:delete, d_score?, {prev, key}})
    send(Ral.CMD, {:insert, key, now, if(rest <= 0, do: 0, else: new_rest)})
    if rest <= 0, do: false, else: true
  end
end
